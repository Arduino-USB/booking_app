from flask import Flask, request, jsonify
import sys
import os
sys.path.append(os.getcwd())
##Now import all of the blueprints

from api.user_mgmt import user_mgmt
from api.booking_mgmt import booking_mgmt





# Create the Flask app
app = Flask(__name__)

# Register blueprint

#To register a BP, use:
app.register_blueprint(user_mgmt, url_prefix="/api/user_mgmt")
app.register_blueprint(booking_mgmt, url_prefix="/api/booking/mgmt")
# Optional: config
app.config['SECRET_KEY'] = 'JHIKBFjhGFHjgFhkJHfVJJUfgJKkHhKkjhjKler578hy7t78ii0ui'


#@app.before_request
#def check_json_body():
#    if request.method in ['POST']:  # optional: only check methods with bodies
#        data = request.get_json()
#        if not data:
#            return jsonify({"error": ["JSON body is empty"]}), 400


if __name__ == "__main__":
	app.run(debug=True)
