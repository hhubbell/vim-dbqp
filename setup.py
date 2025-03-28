from setuptools import setup
import os
import re


def get_version():
    with open(os.path.join("odbcpersist", "__init__.py"), 'r') as f:
        return re.search("^__version__ = \"(.*)\"$", f.read(), re.M).group(1)


setup(
    name="odbcpersist",
    version=get_version(),
    description="Persist an odbc connection using a minimal proxy process",
    packages=["odbcpersist"],
    entry_points={
        "console_scripts": [
            "odbcpersist-start=odbcpersist.server:daemon",
            "odbcpersist-kill=odbcpersist.controller:kill",
            "odbcpersist-ttl=odbcpersist.controller:ttl",
            "odbcpersist-query=odbcpersist.controller:query"]})
