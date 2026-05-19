-- Description: Create external tables for bronze dataset in BigQuery
-- Please do not forget to replace the bucket path

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.ha_departments`
(
  deptid STRING,
  name   STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-a/departments/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.ha_encounters`
(
  encounterid   STRING,
  patientid     STRING,
  encounterdate STRING,
  encountertype STRING,
  providerid    STRING,
  departmentid  STRING,
  procedurecode STRING,
  inserteddate  STRING,
  modifieddate  STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-a/encounters/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.ha_patients`
(
  PatientID    STRING,
  FirstName    STRING,
  LastName     STRING,
  MiddleName   STRING,
  SSN          STRING,
  PhoneNumber  STRING,
  Gender       STRING,
  DOB          STRING,
  Address      STRING,
  ModifiedDate STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-a/patients/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.ha_providers`
(
  providerid     STRING,
  firstname      STRING,
  lastname       STRING,
  specialization STRING,
  deptid         STRING,
  npi            STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-a/providers/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.ha_transactions`
(
  transactionid  STRING,
  encounterid    STRING,
  patientid      STRING,
  providerid     STRING,
  deptid         STRING,
  visitdate      STRING,
  servicedate    STRING,
  paiddate       STRING,
  visittype      STRING,
  amount         STRING,
  amounttype     STRING,
  paidamount     STRING,
  claimid        STRING,
  payorid        STRING,
  procedurecode  STRING,
  icdcode        STRING,
  lineofbusiness STRING,
  medicaidid     STRING,
  medicareid     STRING,
  insertdate     STRING,
  modifieddate   STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-a/transactions/*.json']
);

---------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.hb_departments`
(
  deptid STRING,
  name   STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-b/departments/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.hb_encounters`
(
  encounterid   STRING,
  patientid     STRING,
  encounterdate STRING,
  encountertype STRING,
  providerid    STRING,
  departmentid  STRING,
  procedurecode STRING,
  inserteddate  STRING,
  modifieddate  STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-b/encounters/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.hb_patients`
(
  id           STRING,
  f_name       STRING,
  l_name       STRING,
  m_name       STRING,
  ssn          STRING,
  phonenumber  STRING,
  gender       STRING,
  dob          STRING,
  address      STRING,
  modifieddate STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-b/patients/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.hb_providers`
(
  providerid     STRING,
  firstname      STRING,
  lastname       STRING,
  specialization STRING,
  deptid         STRING,
  npi            STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-b/providers/*.json']
);

CREATE OR REPLACE EXTERNAL TABLE `project-f1c63dcd-3c29-4fb0-95a.bronze_dataset.hb_transactions`
(
  transactionid  STRING,
  encounterid    STRING,
  patientid      STRING,
  providerid     STRING,
  deptid         STRING,
  visitdate      STRING,
  servicedate    STRING,
  paiddate       STRING,
  visittype      STRING,
  amount         STRING,
  amounttype     STRING,
  paidamount     STRING,
  claimid        STRING,
  payorid        STRING,
  procedurecode  STRING,
  icdcode        STRING,
  lineofbusiness STRING,
  medicaidid     STRING,
  medicareid     STRING,
  insertdate     STRING,
  modifieddate   STRING
)
OPTIONS (
  format = 'JSON',
  uris   = ['gs://healthcare-bucket-thaodtp/landing/hospital-b/transactions/*.json']
);
