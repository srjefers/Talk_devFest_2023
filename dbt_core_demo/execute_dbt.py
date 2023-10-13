import os
import json
import subprocess

def main():
    dbt_command = os.environ.get('dbt_command', 'dbt run-operation stage_external_sources && dbt run --select silver')
    subprocess.run(['sh','-c',dbt_command], check=True)

if __name__ == '__main__':
    print('Execution starts --->>')
    main()