DROP TABLE todos;
DROP TABLE lists;

CREATE TABLE lists (
	id serial PRIMARY KEY, 
	name text NOT NULL UNIQUE
);

CREATE TABLE todos (
	id serial PRIMARY KEY, 
	name text NOT NULL, 
	completed boolean DEFAULT false,
	list_id int NOT NULL REFERENCES lists(id) ON DELETE CASCADE
);

INSERT INTO lists (name) VALUES ('groceries'), ('chores'), ('school');
INSERT INTO todos (name, list_id) VALUES 
	('apples', 1), 
	('bananas', 1),
	('wash dishes', 2),
	('clean room', 2),
	('homework', 3)