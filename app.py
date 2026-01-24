from flask import Flask
import sys
import os
sys.path.append(os.getcwd())
print(f"syspath {sys.path}")
##Now import all of the blueprints

from api.user_mgmt import user_mgmt






# Create the Flask app
app = Flask(__name__)

# Register blueprint

#To register a BP, use:
app.register_blueprint(user_mgmt, url_prefix="/api")

# Optional: config
app.config['SECRET_KEY'] = 'JHIKBFjhGFHjgFhkJHfVJJUfgJKkHhKkjhjKler578hy7t78ii0ui'



if __name__ == "__main__":
	app.run(debug=True)
