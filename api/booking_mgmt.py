from flask import Blueprint, request, url_for, session, jsonify
from db_core import sql
from sql_commands import booking_commands, user_commands
import psycopg2.errors as sql_errors
from datetime import datetime


booking_mgmt = Blueprint('booking_mgmt', __name__)


@booking_mgmt.before_request
def check_user_logged_in():
	if "id" not in session:
		return jsonify({"error" : ["You are not logged in"]})



def check_time(ts: str) -> bool:
	ts = ts.strip()

	# Must include at least hour information
	if "T" not in ts and " " not in ts:
		return False

	# Handle UTC Z
	if ts.endswith("Z"):
		ts = ts[:-1] + "+00:00"

	try:
		dt = datetime.fromisoformat(ts)
	except ValueError:
		return False

	# Ensure time component is present (not date-only)
	return dt.hour is not None

@booking_mgmt.route('/create_resv', methods=['POST'])
def create_resv():
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
	
	if data.get("start") is not None and check_time(data["start"]) == False:
		errors.append("The start timestamp is in an incorrect format")

	if data.get("end") is not None and check_time(data["end"]) == False:
		errors.append("The end timestamp is in an incorrect format")
	
	if "server_id" not in data:
		errors.append("You must provide a server_id, or the ID of the person who is offering the service")

	if errors:
		return jsonify({"error" : errors})

	query = sql(booking_commands["CREATE_RESV"], args={"start" : data["start"], "end" : data["end"], "user_id" : session["id"], "server_id" : data["server_id"]})

	#Actually doing the thing
	
	if isinstance(getattr(query, "orig", None), sql_errors.RaiseException):
		return jsonify({"error" : str(query.orig.pgerror).split("\n")})
	
	print(query)	
	
	if query == True:
		return jsonify({"message" : ["Successfully booked timestamp"]})

	return jsonify({"error" : "err with query"})

@booking_mgmt.route('/delete_resv', methods=['POST'])
def delete_resv():
	data = request.get_json()


	if "id" not in data:
		return jsonify({"error" : ["You must provide a booking ID to delete"]})

	query = sql(booking_commands["CHECK_USER_OWN_BOOKING"], args={"user_id" : session["id"], "id" : data["id"]})
	

		
	if not query:
		return jsonify({"error" : ["You do not own this resv"]})
	
	query = sql(booking_commands["DELETE_RESV_BY_ID"], args={"id" : data["id"]})

	if query == True:
		return jsonify({"message" : ["Succesfully deleted resv"]})
	
	return jsonify({"error" : "err with query"})

@booking_mgmt.route('/add_slot', methods=['POST'])
def add_slot():
	data = request.get_json()
	# data.keys = ["start", "end"]
	
	errors = []

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
	
	return jsonify({"error" : "err with query"})

@booking_mgmt.route('/delete_slot', methods=['POST'])
def delete_slot():
	data = request.get_json()
	# data.keys = ["start", "end"]
	
	errors = []

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

	return jsonify({"error" : "err with query"})

@booking_mgmt.route('/get_booked_by_month', methods=["POST"])
def get_booked_by_month():
	data = request.get_json()
	
	if "month" not in data:
		return jsonify({"error" : ["You must provde a month"]})
	
	if not check_time(data["month"]):
		return jsonify({"error" : ["Incorrect time format (must be yyyy-mm)"]})
	
	query = sql(booking_commands["GET_RESV_PER_MONTH"], args={"month" : data["month"]})

	if isinstance(query, Exception):
		return jsonify({"error" : str(query).split["\n"]})
		
	
	return jsonify({"resvs" : query})
	
	
	
