user_commands = {
	"GET_HASHED_PASSWORD" : "SELECT pass FROM users WHERE username = :user",
	"GET_HASHED_PASSWORD_BY_ID" : "SELECT pass FROM users WHERE id = :id",
	"CREATE_USER" : "INSERT INTO users (username, pass, name, type) VALUES (:username, :password, :name, 'user')",
	"CHANGE_PASSWORD" : "UPDATE users SET pass = :pswd WHERE id = :id",
	"GET_USER_DATA" : "SELECT * FROM users WHERE id = :id",
	"CHECK_USER_EXISTS" : "SELECT EXISTS(SELECT 1 FROM users WHERE username = :username)",
	"GET_USER_DATA_BY_USERNAME" : "SELECT * FROM users WHERE username = :username",
	"GET_USER_PASSWORD_BY_USERNAME" : "SELECT pass FROM users WHERE username = :username"
}

booking_commands = {
	"CREATE_RESV" : "insert into booking (date_resv_start, date_resv_end, created_by, server_id) values (:start, :end, :user_id, :server_id);",
	"GET_RESV_PER_MONTH" : "select * from booking where date_resv >= date_trunc('month', DATE :month ) and date_resv <  date_trunc('month', DATE :month) + INTERVAL '1 month';",
	"DELETE_RESV_BY_ID" : "delete from booking where id = :id;",
	"ADD_OPEN_SLOT" : "insert into booking_open (user_id, start_time, end_time) values (:id, :start, :end);",
	"DELETE_OPEN_SLOT_BY_ID" : "delete from booking_open where id = :id;",
	"GET_SLOT_BY_ID" : "select * from booking_open where id = :id;",
	"CHECK_USER_OWN_BOOKING" : "select * from booking where created_by = :user_id and id = :id;"
}
