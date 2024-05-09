require "pg"

class DatabasePersistence 
	def initialize(logger)
		@db = PG.connect(dbname: "todolist")
		@logger = logger
	end

	def query(statement, *params)
		@logger.info "#{statement}: #{params}"
		@db.exec_params(statement, params)
	end

	def find_list(id)
		sql = <<~HEREDOC 
			SELECT l.*, COUNT(t.id), COUNT(NULLIF(t.completed, true)) as todos_remain 
				FROM lists AS l 
				JOIN todos AS t ON l.id = t.list_id 
				GROUP BY l.id
				HAVING l.id = $1
				ORDER BY l.id
		HEREDOC
		result = query(sql, id)
		tuple = result.first
		tuple_to_list(tuple)
	end

	def all_lists
		sql = <<~HEREDOC 
			SELECT l.*, COUNT(t.id), COUNT(NULLIF(t.completed, true)) as todos_remain 
				FROM lists AS l 
				JOIN todos AS t ON l.id = t.list_id 
				GROUP BY l.id
				ORDER BY l.id
		HEREDOC
		result = query(sql)
		result.map do |tuple|
			tuple_to_list(tuple)
		end
	end

	def create_new_list(list_name)
		sql = "INSERT INTO lists (name) VALUES ($1)"
		query(sql, list_name)
	end

	def delete_list(id)
		list_sql = "DELETE FROM lists WHERE id = $1"
		todos_sql = "DELETE FROM todos WHERE list_id = $1"
		query(list_sql, id)
		query(todos_sql, id)
	end

	def update_list_name(id, new_name)
		sql = "UPDATE lists SET name = $1 WHERE id = $2"
		query(sql, new_name, id)
	end

	def create_new_todo(list_id, todo_name)
		sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
		query(sql, todo_name, list_id)
	end

	def delete_todo_from_list(list_id, todo_id)
		sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
		query(sql, todo_id, list_id)
	end

	def update_todo_status(list_id, todo_id, status)
		sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
		query(sql, status, todo_id, list_id)
	end

	def mark_all_todos_as_completed(list_id)
		sql = "UPDATE todos SET completed = true WHERE list_id = $1"
		query(sql, list_id)
	end

	def find_todos(list_id)
		sql = "SELECT * FROM todos WHERE list_id = $1"
		result = query(sql, list_id)
		result.map do |tuple|
			completed = tuple["completed"] == "t"
			{ id: tuple["id"].to_i, name: tuple["name"], completed: completed }
		end
	end

	private 
	
	def tuple_to_list(tuple)
		{ id: tuple["id"].to_i, 
			name: tuple["name"], 
			todos_count: tuple["count"].to_i, 
			todos_remain: tuple["todos_remain"].to_i }
	end 
end