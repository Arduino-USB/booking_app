user_commands = {
	"GET_HASHED_PASSWORD": (
		"SELECT pass "
		"FROM users "
		"WHERE username = :user"
	),

	"GET_HASHED_PASSWORD_BY_ID": (
		"SELECT pass "
		"FROM users "
		"WHERE id = :id"
	),

	"CREATE_USER": (
		"INSERT INTO users (username, pass, name, type) "
		"VALUES (:username, :password, :name, 'user')"
	),

	"CHANGE_PASSWORD": (
		"UPDATE users "
		"SET pass = :password "
		"WHERE id = :id"
	),

	"GET_USER_DATA": (
		"SELECT * "
		"FROM users "
		"WHERE id = :id"
	),

	"CHECK_USER_EXISTS": (
		"SELECT EXISTS ("
			"SELECT 1 "
			"FROM users "
			"WHERE username = :username"
		")"
	),

	"GET_USER_DATA_BY_USERNAME": (
		"SELECT * "
		"FROM users "
		"WHERE username = :username"
	),

	"GET_USER_PASSWORD_BY_USERNAME": (
		"SELECT pass "
		"FROM users "
		"WHERE username = :username"
	)
}

booking_commands = {
	"CREATE_RESV": (
		"INSERT INTO booking (date_resv_start, date_resv_end, created_by, server_id, key) "
		"VALUES (:start, :end, :user_id, :server_id, :key)"
	),

	"GET_RESV_PER_MONTH": (
		"SELECT date_resv_start, date_resv_end, server_id "
		"FROM booking "
		"WHERE date_resv_start < date_trunc('month', to_date(:month, 'YYYY-MM')) + INTERVAL '1 month' "
		"AND date_resv_end >= date_trunc('month', to_date(:month, 'YYYY-MM'))"
	),


	"ADD_OPEN_SLOT": (
		"INSERT INTO booking_open (user_id, start_time, end_time) "
		"VALUES (:id, :start, :end)"
	),

	"DELETE_OPEN_SLOT_BY_ID": (
		"DELETE "
		"FROM booking_open "
		"WHERE id = :id"
	),

	"GET_SLOT_BY_ID": (
		"SELECT * "
		"FROM booking_open "
		"WHERE id = :id"
	),

	"CHECK_USER_OWN_BOOKING": (
		"SELECT * "
		"FROM booking "
		"WHERE created_by = :user_id "
		"AND id = :id"
	),
	
	"CHECK_KEY_OWN_BOOKING": (
		"SELECT * "
		"FROM booking "
		"WHERE key = :key "
		"AND id = :id"
	),
	
	"GET_ALL_OPEN_SLOTS" : (
		"SELECT * "
		"FROM booking_open"	
	)
	

}

key_commands = {
	"INSERT_KEY_RETURN_ID": (
		"INSERT INTO keys (key) "
		"VALUES (:key) "
		"RETURNING id"	
	),	
	
	"CHECK_KEY_EXIST": (
		"SELECT EXISTS ("
			"SELECT 1 "
			"FROM keys "
			"WHERE key = :key"
		")"
	)


}

menu_commands = {
	"GET_ALL_MENU_ITEMS": (
		"SELECT * "
		"FROM menu"	
	),
	
	"CHECK_MENU_LENGTH_BY_ID" : (
		"SELECT length "
		"FROM menu "	
		"WHERE id = : id"
	),
	
	"INSET_MENU_ITEM" : (
		"INSERT INTO menu (name, length, price) "
		"VALUES (:name, :length, :price)"	
	)
}

