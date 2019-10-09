from azure.cosmosdb.table.tableservice import TableService
from azure.cosmosdb.table.models import Entity
import os

# Azure Storage
AZURE_STORAGE_ACCT = os.environ['AZURE_STORAGE_ACCT']
AZURE_STORAGE_KEY = os.environ['AZURE_STORAGE_KEY']

# Table Name
table_name=oncall

table_service = TableService(account_name=AZURE_STORAGE_ACCT, account_key=AZURE_STORAGE_KEY)
table_service.create_table(table_name)

first = {'PartitionKey': '1', 'RowKey': '1',
        'email': 'jahand@microsoft.com', 'handle': '@JasonHand', table_name: 'true', 'pagingpref': 'push'}

second = {'PartitionKey': '1', 'RowKey': '2',
        'email': 'nepeters@microsoft.com', 'handle': '@nepeters', table_name: 'false', 'pagingpref': 'pager'}

table_service.insert_entity(table_name, first)
table_service.insert_entity(table_name, second)