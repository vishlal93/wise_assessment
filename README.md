# Wise MXN==>USD Launch Analysis

This repo contains the scripts used to cleanse and analyse the data for the MXN==>USD Launch

## 1) raw_data_import - Python

This script uploads the raw CSV file into a Duck DB database for querying in SQL

There were a number of edits made to the file before uploading:

- Changing the dt column from string to date
- Creating a new date column to account for transfer events that were part of the same transaction but ran across two days
- Creating a transfer_id column to uniquely identify individual transactions

## 2) Fix Experience Dimension - SQL

There appeared to be a tagging error in the experience column. Some users were tagged as "New" having had previous transactions tagged as "Existing"
My assumptions were as follows:
- A user tagged "New" at any point was indeed a New user.
- A user could only move from "New" to "Existing" once they had triggered the "Transfer Transferred" event

This script finds users affected by the tagging error and applies a fix so that their "New" tag applies to all transactions before and including them triggering the "Transfer Transferred" event

The output is the WISE_TASK_BUILD table which is the basis for the SQL scripts made to create the views.

## 3) Funnel Build
This script creates a base table that is used in the Conversion Funnel script. 

## 4) Conversion Funnel Build & Retention Views 
These scripts are used to build the views on Acquisition, Conversion and Retention
