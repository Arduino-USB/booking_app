user_commands = {
	"GET_HASHED_PASSWORD" : "SELECT pass FROM users WHERE username = :user",
	"GET_HASHED_PASSWORD_BY_ID" : "SELECT pass FROM users WHERE id = :id",
	"CREATE_USER" : "INSERT INTO users (username, pass, name) VALUES (:username, :password, :name)",
	"CHANGE_PASSWORD" : "UPDATE users SET pass = :pswd WHERE id = :id",
	"GET_USER_DATA" : "SELECT * FROM users WHERE id = :id",
	"CHECK_USER_EXISTS" : "SELECT EXISTS(SELECT 1 FROM users WHERE username = :username)",
	"GET_USER_DATA_BY_USERNAME" : "SELECT * FROM users WHERE username = :username",
	"GET_USER_PASSWORD_BY_USERNAME" : "SELECT pass FROM users WHERE username = :username"
}

