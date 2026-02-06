from flask import Blueprint, request, url_for, session, jsonify
from db_core import sql
from sql_commands import user_commands
import psycopg2.errors as sql_errors
import bcrypt

user_mgmt = Blueprint('user_mgmt', __name__)


@user_mgmt.route('/create_user', methods=["POST"])
def create_user():
	data = request.get_json()
	errors = []	
	if not "username" in data:
		errors.append("You must provide a username")
	if not "password" in data:
		errors.append("You must provide a password")
	if not "name" in data:
		errors.append("You must provide a name")
	if errors:
		return jsonify({ "error" : errors }), 400

	password_hashed = bcrypt.hashpw(bytes(data["password"], "UTF-8"), bcrypt.gensalt())
	query = sql(user_commands["CREATE_USER"], args={"username" : data["username"], "password" : password_hashed, "name" : data["name"]})
		
	if isinstance(getattr(query, "orig", None), sql_errors.UniqueViolation):
		return jsonify({"error" : ["User with this username already exists"]})
	
	query = sql(user_commands["CHECK_USER_EXISTS"], args={"username" : data["username"]}, enable_columns=False)
	
	if query == False:
		return jsonify({"error" : ["Backend error; user not created even when tests passed (what???)"]}), 500
	
	
	query = sql(user_commands["GET_USER_DATA_BY_USERNAME"], args={"username" : data["username"]})
	
	if isinstance(query, list):
		return jsonify({"error" : ["Someone by that username already exists (BACKEND DB ERRROR) "]})

	session["id"] = query["id"]	
	
	
	return jsonify({"message" : ["User created", "Logged in"], "redirect" : "REDIRECT_HERE"}), 200


@user_mgmt.route('/log_in', methods=["POST"])
def log_in():
	data = request.get_json()	
	errors = []
	if not "username" in data:
		errors.append("You must provide a username")
	if not "password" in data:
		errors.append("You must provide a password")
	if errors:
		return jsonify({"error" : errors})

	query = sql(user_commands["CHECK_USER_EXISTS"], args={"username" : data["username"]}, enable_columns=False)

	if query == False:
		return jsonify({"error" : ["Username or password is incorrect"]}), 400
	query = sql(user_commands["GET_USER_PASSWORD_BY_USERNAME"], args={"username" : data["username"]}, enable_columns=False) 
	
	#PostgreSQL specific
	pulled_password  = bytes.fromhex(query[2:]) 
	password_check = bcrypt.checkpw(bytes(data["password"], "UTF-8"), pulled_password)
	
	if not password_check:
		return jsonify({"error" : ["Username or password is incorrect"]}), 400
	
	query = sql(user_commands["GET_USER_DATA_BY_USERNAME"], args={"username" : data["username"]})
	
	if query:
		print(session)
		session["id"] = query["id"] 
		return jsonify({"message" : ["Logged in"], "redirect" : "REDIRECT_HERE"})
	
	return jsonify({"error" : ["sql error"]})

