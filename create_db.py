import sqlite3

conn = sqlite3.connect('Workout.sqlite3')
c = conn.cursor()

try:
    c.execute('''
        CREATE TABLE Day(
          date Date NOT NULL UNIQUE,
          type varchar (16) NOT NULL,
          comments TEXT,
        
          PRIMARY KEY (date)
        
        );
     ''')

except Exception as e:
    print(e)
    pass

try:
    c.execute('''

        CREATE TABLE Reading(
          date Date NOT NULL,
          type varchar(16) NOT NULL,
          value REAL NOT NULL,
        
            PRIMARY KEY (date, type),
          FOREIGN KEY (date) REFERENCES Day(date)
        );
     ''')

except Exception as e:
    print(e)
    pass

try:
    c.execute('''
        CREATE TABLE Workout(
          date Date NOT NULL,
            workout_number INTEGER NOT NULL,
          activity varchar(16) NOT NULL,
          activity_type varchar(16) NOT NULL,
          equipment varchar(32),
          seconds INTEGER NOT NULL,
          rpe REAL NOT NULL,
          tss REAL NOT NULL,
          tss_method varchar(16) NOT NULL,
          km REAL NOT NULL,
          kj REAL NOT NULL,
          ascent_metres REAL NOT NULL,
          reps INTEGER,
          is_race INTEGER NOT NULL,
          cadence INTEGER,
          watts REAL,
          watts_estimated int,
          heart_rate int,
          is_brick int,
          keywords TEXT,
          comments TEXT,
        
            PRIMARY KEY (date, workout_number),
          FOREIGN KEY (date) REFERENCES Day(date)
        );
     ''')

except Exception as e:
    print(e)
    pass
