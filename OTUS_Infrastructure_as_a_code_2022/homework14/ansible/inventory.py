#!/usr/bin/env python3

import argparse
import command
import json
import os
import sys

class YandexInventory(object):
    def __init__(self):
        self.inventory = {}
        self.read_cli_args()
        os.chdir('../terraform')

        if self.args.list:
            self.inventory = self.app_inventory()
        elif self.args.host:
            self.inventory = self.empty_inventory()
        else:
            self.inventory = self.empty_inventory()

        print(json.dumps(self.inventory))

    def app_inventory(self):
        return {
            'wp_app': {
                'hosts': ['app', 'app2'],
                'vars': {}
            },
            '_meta': {
                'hostvars': {
                    'app': {
                        'ansible_host': command.run(['terraform','output','vm_linux_1_public_ip_address']).output.decode("utf-8").replace('"','')
                    },
                    'app2': {
                        'ansible_host': command.run(['terraform','output','vm_linux_2_public_ip_address']).output.decode("utf-8").replace('"','')
                    }
                }
            }
        }

    def empty_inventory(self):
        return {'_meta': {'hostvars': {}}}

    def read_cli_args(self):
        parser = argparse.ArgumentParser()
        parser.add_argument('--list', action = 'store_true')
        parser.add_argument('--host', action = 'store')
        self.args = parser.parse_args()

YandexInventory()
