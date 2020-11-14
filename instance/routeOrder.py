#!/usr/bin/python
import sys
import logging
import random
import datetime
import xml.etree.ElementTree as ET

from classORMNavi import ORMNavi as ORM
from classORMNavi import ORMException

logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.DEBUG)
logging.info('\n=================Create route Started====================')

random.seed()

d = datetime.datetime.now()
try :
    orm = ORM("example2")
    for i in range(212, 290) :
        print (i)
        prs = []
        prs.append(orm.loadProductXMLTree("1"))
        order = orm.createOrder("o-%s" % i, "c2", (d + datetime.timedelta(days=random.randint(12, 45))).strftime("%Y-%m-%d %H:%M:%S"), prs)
        routes = orm.routeOrder(order)
except ORMException :
	logging.critical(sys.exc_info())
	