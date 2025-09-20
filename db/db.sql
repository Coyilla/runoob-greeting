DROP TABLE if EXISTS course;
SET lc_messages='C';
CREATE TABLE course(  
    id SERIAL PRIMARY KEY,
    teacher_id INT NOT NULL,
    name VARCHAR(140) NOT NULL,
    time TIMESTAMP DEFAULT now()
);

INSERT INTO course(id,teacher_id,name,time)
VALUES(1,1,'First course','2022-01-17 05:40:00');

INSERT INTO course(id,teacher_id,name,time)
VALUES(2,1,'Second course','2022-01-18 05:45:00');