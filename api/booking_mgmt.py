from flask import Blueprint, request, url_for, session, jsonify
from db_core import sql, check_pgsql_data
from sql_commands import booking_commands, user_commands, key_commands, menu_commands
import psycopg2.errors as sql_errors
from datetime import datetime
import re
import uuid

booking_mgmt = Blueprint('booking_mgmt', __name__)



@booking_mgmt.before_request
def check_user_logged_in():
	needs_auth = ["add_slot", "delete_slot", "delete_resv"]
	
	if request.endpoint in needs_auth:
		if "id" not in session and "key" not in session:
			return jsonify({"error" : ["You are not logged in"]})




@booking_mgmt.route('/create_resv', methods=['POST'])
def create_resv():
	if "id" in session:
		query = sql(user_commands["GET_USER_DATA"], args={"id" : session["id"]})
		##Error checking
		if query["type"] != "user":
			return jsonify({"error" : ["You can't create a booking/resv as a non-customer"]})		
	
		
	data = request.get_json()
	
	errors = []

	if "start" not in data:
		errors.append("You must provide a start timestamp")
	if "end" not in data:
		errors.append("You must provide a stop timestamp")
	
	if data.get("start") is not None and check_pgsql_data(data["start"], "TIMESTAMP WITHOUT TIME ZONE") == False:
		errors.append("The start timestamp is in an incorrect format")

	if data.get("end") is not None and check_pgsql_data(data["end"], "TIMESTAMP WITHOUT TIME ZONE") == False:
		errors.append("The end timestamp is in an incorrect format")
	
	if "server_id" not in data:
		errors.append("You must provide a server_id, or the ID of the person who is offering the service")
	
	if "menu_id" not in data:
		errors.append("You must provide a menu ID (from the menu options)")

	if errors:
		return jsonify({"error" : errors})
	
	key = str(uuid.uuid4())
	if "id" not in session and "key" not in session:
		key_id = sql(key_commands["INSERT_KEY_RETURN_ID"], args={"key" : key}, enable_columns=False)
	elif "key" in session:
		key_id = session["key"]
	else:
		key_id == None
	
	
	
	query = sql(booking_commands["CREATE_RESV"], args={"start" : data["start"], "end" : data["end"], "user_id" : session["id"] if "id" in session else None, "server_id" : data["server_id"], "key" : key_id, "menu_id" : data["menu_id"]})
	
	

	#Actually doing the thing
	
	if isinstance(query, Exception):
		return jsonify({"error" : str(query.orig.pgerror).split("\n")})
	
	return_val = {"message" : ["Successfully booked timestamp"]}
	
	if "id" not in session and "key" not in session:
		return_val.update({"key" : key})		
		session["key"] = key
	if query == True:
		return jsonify(return_val)

	return jsonify({"error" : ["Something went wrong. Please try again", "If the issue presists please contact developer"]})

@booking_mgmt.route('/delete_resv', methods=['POST'])
def delete_resv():
	data = request.get_json()


	if "id" not in data:
		return jsonify({"error" : ["You must provide a booking ID to delete"]})
	
	if "id" in session:
		query = sql(booking_commands["CHECK_USER_OWN_BOOKING"], args={"user_id" : session["id"], "id" : data["id"]})
	
		if not query:
			return jsonify({"error" : ["You do not own this resv"]})
	else:	
		query = sql(booking_commands["CHECK_KEY_OWN_BOOKING"], args={"key" : session["key"], "id" : data["id"]})
	
		if not query:
			return jsonify({"error" : ["You do not own this resv"]})
			
	
	query = sql(booking_commands["DELETE_RESV_BY_ID"], args={"id" : data["id"]})

	if query == True:
		return jsonify({"message" : ["Succesfully deleted resv"]})
	
	return jsonify({"error" : ["Error creating reservation. Please try again", "If the issue presists please contact developer"]})

@booking_mgmt.route('/add_slot', methods=['POST'])
def add_slot():
	data = request.get_json()
	# data.keys = ["start", "end"]
	
	errors = []
	
	if "id" not in session:
		return jsonify({"error" : ["You are not privilged enough to add a timeslot"]})
		
	if "start" not in data:
		errors.append("You must provide a start timeslot")
	if "end" not in data:
		errors.append("You must provide an end timeslot")	
	
	if errors:
		return jsonify({"error" : errors})
	
	
	query = sql(user_commands["GET_USER_DATA"], args={"id" : session["id"]})

	
	if query.get("type") == "user":
		return jsonify({"error" : ["You are not privilged enough to add a timeslot"]})

	
	query = sql(booking_commands["ADD_OPEN_SLOT"], 
		args={
			"id" : session["id"], 
			"start" : data["start"], 
			"end" : data["end"]
		}
	)
	
	if query == True:
		return jsonify({"message" : ["Successfully added timeslot"]})
	
	return jsonify({"error" : ["Error adding time slot. Please try again", "If the issue presists please contact developer"]})

@booking_mgmt.route('/delete_slot', methods=['POST'])
def delete_slot():
	data = request.get_json()
	# data.keys = ["start", "end"]
	
	errors = []

	if "id" not in session:
		return jsonify({"error" : ["You are not privilged enough to add a timeslot"]})

	if "id" not in data:
		errors.append("You must provide an id for a timeslot")

	
	if errors:
		return jsonify({"error" : errors})
	
	query = sql(user_commands["GET_USER_DATA"], args={"id" : session["id"]})

	
	if query.get("type") == "user":
		return jsonify({"error" : ["You are not privilged enough to delete a timeslot"]})


		
	query = sql(booking_commands["GET_SLOT_BY_ID"], args={"id" : data["id"]})
	
	if query["user_id"] != session["id"]:
		return jsonify({"error" : ["You do not own this booking slot"]})
	
	query = sql(booking_commands["DELETE_OPEN_SLOT_BY_ID"], args={"id" : data["id"]})

	if query == True:
		return jsonify({"message" : "Successfully deleted time slot"})

	return jsonify({"error" : ["Something went wrong. Please try again", "If the issue presists please contact developer"]})

@booking_mgmt.route('/get_booked_by_month', methods=["GET"])
def get_booked_by_month():
	data = request.args
	
	if "month" not in data:
		return jsonify({"error" : ["You must provde a month"]})
	
	if not check_pgsql_data(f"{data["month"]}-01", "DATE"):
		return jsonify({"error" : ["Incorrect time format (must be yyyy-mm)"]})
	
	query = sql(booking_commands["GET_RESV_PER_MONTH"], args={"month" : data["month"]})

	if isinstance(query, Exception):
		return jsonify({"error" : str(query.orig.pgerror).split("\n")})
	
	
	
	return jsonify({"resvs" : [query] if isinstance(query, dict) else query})
	

@booking_mgmt.route('/create_menu_item')
def create_menu_item():
	data = request.get_json()	
	
	if "id" not in session:
		return jsonify({"error" : ["You must be logged in"]})
	
	errors = []

	if "name" not in data:
		errors.append("You must provide the name of the menu item")

	if "length" not in data:
		errors.append("You must provide the length (in time) of the menu item")

	if "price" not in data:
		errors.append("You must provide the price of the menu item")

	if errors:
		return jsonify({"error" : errors})
	
	errors = []
	
	if not check_pgsql_data(data["length"], "INTERVAL"):
		errors.append("The length (in time) of the menu item is in the incoorect format\nExample: '30 minutes'")
	
	
	if check_pgsql_data(data["price"], "INTEGER") and data["price"] < 0:
		errors.append("The price (in cents) must be a postive integer\nExample $3 -> 300")
	
	
	query = sql(user_commands["GET_USER_DATA"], args={"id" : session["id"]})
	
	if not query:
		return jsonify({"error" : ["Something went wrong. Please try again", "If the issue presists please contact developer"]})
	
	if query.get("type") == "user":
		return jsonify({"error" : ["You are not privilged enough to add a menu item"]})
	
	query = sql(menu_commands["INSET_MENU_ITEM"], args={"name" : data["name"], "price" : data["price"], "length" : data["length"]})

	if not query:
		return jsonify({"error" : ["Error creating menu item. Please try again", "If the issue presists please contact developer"]})
	
	return jsonify({"message" : ["Successfully created menu item"]})



@booking_mgmt.route('/get_open_slots', methods=['GET'])
def get_open_slots():
	
	query = sql(booking_commands["GET_ALL_OPEN_SLOTS"])
	
	if isinstance(query, Exception):
		return jsonify({"error" : str(query.orig.pgerror).split("\n")})
	
	return jsonify({"slots": query})
		
	
@booking_mgmt.route('/get_all_menu_items', methods=['GET'])
def get_all_menu_items():
	
	query = sql(menu_commands["GET_ALL_MENU_ITEMS"])
	
	if not query:
		return jsonify({"error" : ["Error fetching menu items", "If the issue presists please contact developer"]})




