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
UPDATE person_name
SET given_name = CONCAT('Patient', person_id),
    middle_name = CONCAT('Patient', person_id),
    family_name = CONCAT('Patient', person_id);

-- Verify the changes in person_name
SELECT person_id, given_name, middle_name, family_name
FROM person_name
WHERE given_name LIKE 'Patient%' LIMIT 5;

-- 3️⃣ Mask birthdates (simple +/- 90 days)
UPDATE person
SET birthdate = DATE_ADD(birthdate, INTERVAL FLOOR(RAND()*180-90) DAY)
WHERE birthdate IS NOT NULL;

-- Verify the changes in person birthdate
SELECT person_id, birthdate
FROM person
WHERE birthdate IS NOT NULL LIMIT 5;

-- 4️⃣ Mask death dates (simple +/- 90 days)
UPDATE person
SET death_date = DATE_ADD(death_date, INTERVAL FLOOR(RAND()*180-90) DAY)
WHERE death_date IS NOT NULL;

-- Verify the changes in person death_date
SELECT person_id, death_date
FROM person
WHERE death_date IS NOT NULL LIMIT 5;

-- 5️⃣ Mask addresses
UPDATE person_address
SET address1 = CONCAT('Address1-', person_id),
    address2 = CONCAT('Address2-', person_id),
    latitude = NULL,
    longitude = NULL;

-- Verify the changes in person_address
SELECT person_id, address1, address2, latitude, longitude
FROM person_address
WHERE address1 LIKE 'Address1-%' LIMIT 5;

-- 6️⃣ Mask locations
UPDATE location
SET name = CONCAT('Location-', location_id);

-- Verify the changes in location
SELECT location_id, name
FROM location
WHERE name LIKE 'Location-%' LIMIT 5;

-- 7️⃣ Mask usernames and passwords
UPDATE users
SET username = CONCAT('username-', user_id),
    password = 'dummy_password'
WHERE username NOT IN ('admin', 'superman', 'superuser');

-- Verify the changes in users
SELECT user_id, username, password
FROM users
WHERE username NOT IN ('admin', 'superman', 'superuser') LIMIT 5;

-- 8️⃣ Mask person attributes
UPDATE person_attribute pa
JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id
SET pa.value = CONCAT(pat.name, '-', pa.person_id)
WHERE pat.name IN ('primaryRelative', 'primaryContact');

-- Verify the changes in person_attribute
SELECT pa.person_id, pa.value, pat.name
FROM person_attribute pa
JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id
WHERE pat.name IN ('primaryRelative', 'primaryContact') LIMIT 5;

-- 9️⃣ Clear sensitive local names
DELETE pa FROM person_attribute pa
JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id
WHERE pat.name IN ('givenNameLocal', 'familyNameLocal', 'middleNameLocal');

-- Verify that the sensitive local names were deleted
SELECT person_id, pa.value, pat.name
FROM person_attribute pa
JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id
WHERE pat.name IN ('givenNameLocal', 'familyNameLocal', 'middleNameLocal') LIMIT 5;
