import sys
import json

from common import convert_base64_to_dict
from app import AppletApplication


def main():
    data = {}
    with open('config.json', 'r') as f:
        data = json.load(f)
    print(data)
    applet_app = AppletApplication(**data)
    applet_app.run()
    applet_app.wait()


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(e)
