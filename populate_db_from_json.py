import json
import sqlite3
from datetime import date
from dateutil import parser

conn = sqlite3.connect('Workout.sqlite3')
c = conn.cursor()

f = open("TrainingDiary.json")
data = json.load(f)

days = data['days']

sleep_quality_map = {'Excellent': 1.0,
                     'Good': 0.8,
                     'Average': 0.5,
                     'Poor': 0.3,
                     'Very Poor': 0.1}

for d in days:
    dDateTime = parser.parse(d['iso8061DateString'])
    dDate = date(dDateTime.year, dDateTime.month, dDateTime.day)
    sqlString = f"""
        INSERT INTO day (date, type, comments)
        VALUES
        ('{dDate}', '{d['type']}', "{d['comments']}");       
    """
    print(sqlString)
    try:
        c.execute(sqlString)
    except Exception as e:
        print(e)

    sqlString = f"""
        INSERT INTO Reading (date, type, value)
        VALUES
        ('{dDate}', 'fatigue', {float(d['fatigue'])}),
        ('{dDate}', 'sleep', {float(d['sleep'])}),
        ('{dDate}', 'sleep_quality', {sleep_quality_map[d['sleepQuality']]}),
        ('{dDate}', 'motivation', {float(d['motivation'])});       
    """
    print(sqlString)
    try:
        c.execute(sqlString)
    except Exception as e:
        print(e)

    if 'workouts' in d:
        workout_number = 0
        for w in d['workouts']:
            try:
                ascent = float(w['ascentMetres']) if w['ascentMetres'] is not None else 0.0
                rpe = float(w['rpe']) if w['rpe'] is not None else 0.0
                kj = float(w['kj']) if w['kj'] is not None else 0.0
                secs = float(w['seconds']) if w['seconds'] is not None else 0.0
                reps = float(w['reps']) if w['reps'] is not None else 0.0
                km = float(w['km']) if w['km'] is not None else 0.0
                isRace = int(w['isRace']) if w['isRace'] is not None else 0
                watts = float(w['watts']) if w['watts'] is not None else 0.0
                cadence = float(w['cadence']) if w['cadence'] is not None else 0.0
                wattsEstimated = int(w['wattsEstimated']) if w['wattsEstimated'] is not None else 0
                hr = float(w['hr']) if w['hr'] is not None else 0.0
                tss = float(w['tss']) if w['tss'] is not None else 0.0
                brick = int(w['brick']) if w['brick'] is not None else 0

                sqlString = f"""INSERT INTO Workout 
                    (date, workout_number, activity, activity_type, equipment, seconds, rpe, tss, tss_method, km,kj,ascent_metres, reps, is_race, cadence, watts, watts_estimated, heart_rate, is_brick, keywords, comments) 
                     VALUES
                     ('{dDate}', {workout_number}, '{w['activityString']}', '{w['activityTypeString']}', '{w['equipmentName']}', {secs}, {rpe}, {tss}, '{w['tssMethod']}',{km}, {kj},  {ascent},  {reps}, {isRace},{cadence},{watts},  {wattsEstimated},{hr}, {brick}, '{w['keywords']}',  "{w['comments']}")
                """
                print(sqlString)
                c.execute(sqlString)
                workout_number += 1
            except TypeError as te:
                print(f'ERROR: {w} and {te}')
                continue

for w in data['weights']:
    dDateTime = parser.parse(w['iso8061DateString'])
    dDate = date(dDateTime.year, dDateTime.month, dDateTime.day)

    c.execute(f'''
        INSERT INTO Reading (date, type, value)
        VALUES
        ('{dDate}', 'kg', {float(w['kg'])})   
    ''')

    if w['fatPercent'] > 0:
        c.execute(f'''
            INSERT INTO Reading (date, type, value)
            VALUES
            ('{dDate}', 'fat_percentage', {float(w['fatPercent'])})                
        ''')

for p in data['physiologicals']:
    dDateTime = parser.parse(p['iso8061DateString'])
    dDate = date(dDateTime.year, dDateTime.month, dDateTime.day)

    try:
        c.execute(f'''
            INSERT INTO Reading (date, type, value)
            VALUES
            ('{dDate}', 'resting_hr', {float(p['restingHR'])})                               
        ''')

        if p['restingSDNN'] is not None and p['restingRMSSD'] is not None:
            c.execute(f'''
                INSERT INTO Reading (date, type, value)
                VALUES
                ('{dDate}', 'sdnn', {float(p['restingSDNN'])}),                             
                ('{dDate}', 'rmssd', {float(p['restingRMSSD'])})                               
            ''')
    except Exception as e:
        print(p)
        print(e)

conn.commit()
