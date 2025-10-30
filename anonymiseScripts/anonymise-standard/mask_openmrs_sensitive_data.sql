SET FOREIGN_KEY_CHECKS=0;

-- 1️⃣ Truncate tables not needed for testing/logs
TRUNCATE TABLE concept_proposal_tag_map;
TRUNCATE TABLE concept_proposal;
TRUNCATE TABLE hl7_in_archive;
TRUNCATE TABLE hl7_in_error;
TRUNCATE TABLE hl7_in_queue;
TRUNCATE TABLE user_property;
TRUNCATE TABLE notification_alert_recipient;
TRUNCATE TABLE notification_alert;
TRUNCATE TABLE failed_events;

SET FOREIGN_KEY_CHECKS=1;

-- 2️⃣ Mask person names
DROP TABLE IF EXISTS random_names;

CREATE TABLE random_names (
  rid INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  PRIMARY KEY (rid),
  UNIQUE KEY name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO  random_names (name)
SELECT DISTINCT TRIM(given_name) FROM person_name WHERE given_name IS NOT NULL;
INSERT IGNORE INTO random_names (name)
SELECT DISTINCT TRIM(middle_name) FROM person_name WHERE middle_name IS NOT NULL;
INSERT IGNORE INTO random_names (name)
SELECT DISTINCT TRIM(family_name) FROM person_name WHERE family_name IS NOT NULL;

DROP PROCEDURE IF EXISTS randomize_names;
DELIMITER //
CREATE PROCEDURE randomize_names()
BEGIN
  DECLARE _size INT;
  DECLARE _start INT DEFAULT 0;
  DECLARE _stepsize INT DEFAULT 300;

  SELECT MAX(person_name_id) INTO _size FROM person_name;

  WHILE _start < _size DO
    UPDATE person_name
    SET given_name = (
        SELECT name FROM (
            SELECT rn.rid, rn.name
            FROM random_names rn
            ORDER BY RAND()
            LIMIT 1
        ) tmp
    ),
    middle_name = given_name,
    family_name = middle_name
    WHERE person_name_id BETWEEN _start AND (_start + _stepsize);

    SET _start = _start + _stepsize + 1;
  END WHILE;
END;
//
DELIMITER ;

CALL randomize_names();
DROP PROCEDURE IF EXISTS randomize_names;

-- 3️⃣ Mask birthdates
UPDATE person
SET birthdate = DATE_ADD(birthdate, INTERVAL FLOOR(RAND()*182-182) DAY)
WHERE birthdate IS NOT NULL AND DATEDIFF(NOW(), birthdate) > 15*365;

UPDATE person
SET birthdate = DATE_ADD(birthdate, INTERVAL FLOOR(RAND()*91-91) DAY)
WHERE birthdate IS NOT NULL AND DATEDIFF(NOW(), birthdate) BETWEEN 5*365 AND 15*365;

UPDATE person
SET birthdate = DATE_ADD(birthdate, INTERVAL FLOOR(RAND()*30-30) DAY)
WHERE birthdate IS NOT NULL AND DATEDIFF(NOW(), birthdate) < 5*365;

UPDATE person SET birthdate_estimated = CAST(RAND() AS SIGNED);

-- 4️⃣ Mask death dates
UPDATE person
SET death_date = DATE_ADD(death_date, INTERVAL FLOOR(RAND()*91-91) DAY)
WHERE death_date IS NOT NULL;

-- 5️⃣ Mask person addresses
UPDATE person_address
SET address1 = CONCAT('address1-', person_id),
    address2 = CONCAT('address2-', person_id),
    city_village = CONCAT('city-', person_id),  -- Mask city_village
    latitude = NULL,
    longitude = NULL,
    date_created = NOW(),
    date_voided = NOW();


-- 6️⃣ Mask locations
UPDATE location
SET name = CONCAT('Location-', location_id);

-- 7️⃣ Mask users
UPDATE users
SET username = CONCAT('username-', user_id)
WHERE username NOT IN ('admin', 'superman', 'superuser');

UPDATE users
SET password = '4a1750c8607dfa237de36c6305715c223415189',
    salt = 'c788c6ad82a157b712392ca695dfcf2eed193d7f',
    secret_question = NULL,
    secret_answer = NULL
WHERE username NOT IN ('admin', 'superman', 'superuser');

UPDATE global_property
SET property_value = 'admin'
WHERE property LIKE '%.username';

UPDATE global_property
SET property_value = 'test'
WHERE property LIKE '%.password';

-- 8️⃣ Mask patient identifiers
DROP TABLE IF EXISTS temp_patient_identifier_old;  -- <-- add this line
CREATE TABLE temp_patient_identifier_old(patient_id INT, identifier VARCHAR(256), PRIMARY KEY(patient_id));
INSERT INTO temp_patient_identifier_old SELECT patient_id, identifier FROM patient_identifier;



TRUNCATE patient_identifier;

INSERT INTO patient_identifier (patient_id, identifier, identifier_type, location_id, preferred, creator, date_created, voided, uuid)
SELECT p.patient_id,
       CONCAT((SELECT prefix FROM idgen_seq_id_gen ORDER BY RAND() LIMIT 1), p.patient_id),
       (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE name = 'Bahmni Id'),
       1, 1, 1, '20080101', 0, UUID()
FROM patient p;

CREATE TABLE temp_person_uuid_old(person_id INT, uuid VARCHAR(256), PRIMARY KEY(person_id));
INSERT INTO temp_person_uuid_old SELECT person_id, uuid FROM person;

-- 9️⃣ Mask person attributes
UPDATE person_attribute pa
INNER JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id
SET pa.value = CONCAT('primaryRelative-', pa.person_id)
WHERE pat.name = 'primaryRelative';

UPDATE person_attribute pa
INNER JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id
SET pa.value = FLOOR(POW(10,9) + RAND() * (POW(10,10) - POW(10,9)))
WHERE pat.name = 'primaryContact';

DELETE pa
FROM person_attribute pa
INNER JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id
WHERE pat.name IN ('givenNameLocal', 'familyNameLocal', 'middleNameLocal');

-- 🔟 Mask visit, encounter, obs dates
ALTER TABLE visit ADD COLUMN rand_increment INT;

UPDATE visit
SET rand_increment = CAST(RAND()*91-91 AS SIGNED),
    date_started = ADDDATE(date_started, rand_increment),
    date_stopped = IF(date_stopped IS NULL, NULL, ADDDATE(date_stopped, rand_increment)),
    date_voided = IF(date_voided IS NULL, NULL, ADDDATE(date_voided, rand_increment)),
    date_created = ADDDATE(date_created, rand_increment);

UPDATE encounter e
JOIN visit v ON e.visit_id = v.visit_id
SET e.encounter_datetime = ADDDATE(e.encounter_datetime, v.rand_increment),
    e.date_voided = IF(e.date_voided IS NULL, NULL, ADDDATE(e.date_voided, v.rand_increment)),
    e.date_created = ADDDATE(e.date_created, v.rand_increment);

UPDATE obs o
JOIN encounter e ON e.encounter_id = o.encounter_id
JOIN visit v ON e.visit_id = v.visit_id
SET o.obs_datetime = ADDDATE(o.obs_datetime, v.rand_increment),
    o.date_created = ADDDATE(o.date_created, v.rand_increment),
    o.date_voided = IF(o.date_voided IS NULL, NULL, ADDDATE(o.date_voided, v.rand_increment)),
    o.value_datetime = IF(o.value_datetime IS NULL, NULL, ADDDATE(o.value_datetime, v.rand_increment));

ALTER TABLE visit DROP COLUMN rand_increment;
