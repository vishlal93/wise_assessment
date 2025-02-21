###### This script takes the raw file makes the below changes and upload the table into a duckdb database
# Convert dt into a timestamp
# Create a new date column for transactions that go across multiple days
# Create a transfer_id column to group transfer_events

import duckdb
import pandas as pd
import os
import uuid

# Find file and duckdb
folder_path = r"C:\Users\user\Documents\Wise Assessment"
csv_file = os.path.join(folder_path, "wise_funnel_events_regional.csv")
db_file = os.path.join(folder_path, "wise.duckdb")

# Load CSV
df = pd.read_csv(csv_file)

# Convert 'dt' from string to date
df['dt'] = pd.to_datetime(df['dt'])



#######This section creates a new date column for any transactions that happen to cross over into another day from one event to another #########

# Dictionary for order of events
event_code = {'Transfer Created': 1, 'Transfer Funded': 2, 'Transfer Transferred': 3}

# New column showing event order
df['event_code'] = df['event_name'].map(event_code)

# sort data
df = df.sort_values(by=['user_id', 'dt', 'event_code'])
# Create a new column showing the previous event for each row
df['previous_event'] = df.groupby(['user_id'])['event_code'].shift(1)

# Create a new column showing the previous event date for each row

df['previous_event_date'] = df.groupby(['user_id'])['dt'].shift(1)


# UPDATE DT IF THE FUNDED EVENT DATE CROSSES OVER
def funded_event_date(row):

    if row['event_code'] == 2 and row['previous_event'] == 1 and row['dt'] != row['previous_event_date']:
        return row['previous_event_date']

    return row['dt']

# Apply the function to update 'dt' column
df['updated_dt'] = df.apply(funded_event_date, axis=1)

# Create a new column showing the previous event for each row
df['previous_event_date'] = df.groupby(['user_id'])['updated_dt'].shift(1)

# UPDATE DT IF THE TRANSFERRED EVENT DATE CROSSES OVER
def transferred_event_date(row):

    if row['event_code'] == 3 and row['previous_event'] == 2 and row['updated_dt'] != row['previous_event_date']:
        return row['previous_event_date']

    return row['updated_dt']

# Apply the function to update 'dt' column
df['updated_dt'] = df.apply(transferred_event_date, axis=1)

#######END OF DATE UPDATE SECTION #########

#######This section builds  UUID for the Transfer_id column that groups events by user,day,region and platfrom#########

# Create a UUID based on user_id, dt, region, and platform
def generate_uuid(user_id, dt, region, platform):
    return uuid.uuid5(uuid.NAMESPACE_DNS, f"{user_id}-{dt}-{region}-{platform}")

# Generate UUIDs
df["transfer_id"] = df.groupby(["user_id", "updated_dt", "region", "platform"])["user_id"].transform(
    lambda x: generate_uuid(
        x.iloc[0],
        df.loc[x.index[0], "updated_dt"],
        df.loc[x.index[0], "region"],
        df.loc[x.index[0], "platform"]
    )
)

##########END OF TRANSFER_ID CREATION#########

# Drop unused columns
df = df.drop(columns=['event_code', 'previous_event','previous_event_date'])

print(df)

# Connect to DuckDB and upload data
con = duckdb.connect(db_file)


con.execute("""
CREATE OR REPLACE TABLE wise_funnel_events_regional (
    event_name VARCHAR,
    dt DATETIME,
    user_id INT,
    region VARCHAR,
    platform VARCHAR,
    experience VARCHAR,
    updated_dt DATETIME,
    transfer_id VARCHAR
)
""")


con.from_df(df).insert_into('wise_funnel_events_regional')

con.close()

print(f"Data Loaded")
