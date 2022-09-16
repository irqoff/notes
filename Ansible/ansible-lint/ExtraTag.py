# irqoff@2022

from ansiblelint.rules import AnsibleLintRule
from yaml import load

try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader

class ExtraTag(AnsibleLintRule):
    id = 'H00001'
    description = 'Use tags on playbook-level for tagging all tasks in a role'
    tags = ['H00001']
    done = []

    def matchyaml(self, file):
        result = []
        number_of_tasks = 0
        playbook_tags = {}

        if file.kind != "tasks":
            return result
        if file.path.name != "main.yml":
            return result
        if file.path in self.done:
            return result

        with open(file.path) as f:
            tasks = load(f,Loader=Loader)
        for task in tasks:
            number_of_tasks += 1
            if "tags" in task:
                if isinstance(task['tags'],str):
                    playbook_tags[task['tags']] = playbook_tags.get(task['tags'],0) + 1 
                if isinstance(task['tags'],list):
                    for tag in task['tags']:
                         playbook_tags[tag] = playbook_tags.get(tag,0) + 1

        for tag in playbook_tags:
             if playbook_tags[tag] == number_of_tasks:
                 result.append(self.create_matcherror(filename=file))

        self.done.append(file.path)
        return result
