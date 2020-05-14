from locust import HttpLocust, TaskSet, between
import random


def index(l):
    r = random.random()
    indexstr = "/index.html?OK=" + str(r)
    l.client.get(indexstr,headers={"User-Agent":"LOCUST 5.6"},name="/index.html?notok=[random]")


class UserBehavior(TaskSet):
    tasks = {index: 1}

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    wait_time = between(0.1,0.1)
