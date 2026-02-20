from sqlalchemy import text, create_engine
from sqlalchemy.exc import SQLAlchemyError
import psycopg2
import re

engine = create_engine("postgresql+psycopg2://db_user:lXLUIUFpy4vlAkAPNMYLpUhRr2QIU6m7@localhost:5432/db", future=True)

# Ordered: most specific → most generic



def sql(cmd, fetch=None, enable_columns=True, args=None, page=None, page_size=None, check_next_page=False):

	if page is not None and page_size is not None:
		offset = (page - 1) * page_size
		cmd = f"{cmd} LIMIT {page_size + 1} OFFSET {offset}"


	try:
		with engine.begin() as conn:
			result = conn.execute(text(cmd), args or {})

			# Statements that return no rows (INSERT, UPDATE, CREATE, etc.)
			if not result.returns_rows:
				return True

			# Fetch rows
			if fetch is None:
				rows = result.fetchall()
			else:
				rows = result.fetchmany(fetch)

	except SQLAlchemyError as e:
		print("SQL ERROR:", e)
		return e



	# Convert result rows to list
	out_list = []
	for row in rows:
		if len(row) == 1 and not enable_columns:
			out_list.append(row[0])
		else:
			out_list.append(list(row))

	# If column dict output is enabled
	if enable_columns:
		columns = list(result.keys())  # Important: convert RMKeyView to list
		out_list = [
			{columns[i]: row[i] for i in range(len(row))}
			for row in out_list
		]

	# Handle pagination
	has_next_page = False
	if page_size is not None and len(out_list) > page_size:
		has_next_page = True
		out_list = out_list[:page_size]

	# If single row and enable_columns is False
	if not enable_columns and len(out_list) == 1:
		out_list = out_list[0]

	if check_next_page:
		return out_list, has_next_page
	
	if isinstance(out_list, list) and len(out_list) == 1: 
		return out_list[0]

	return out_list





def check_pgsql_data(value, data_type):
	"""
	Returns True if value can be cast to the given PostgreSQL data_type.
	Otherwise returns False.

	Example:
		check_pgsql_data("30 minutes", "INTERVAL") -> True
		check_pgsql_data("30 minutes", "INTEGER")  -> False
	"""

	# Allow only safe type names (prevents SQL injection via data_type)
	if not re.fullmatch(r"[A-Za-z0-9_\[\]\s]+", data_type):
		return False

	try:
		with engine.begin() as conn:
			conn.execute(
				text(f"SELECT CAST(:value AS {data_type})"),
				{"value": value}
			)
		return True

	except SQLAlchemyError:
		return False

