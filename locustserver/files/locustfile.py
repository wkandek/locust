from locust import HttpLocust, TaskSet, between
import random


def index(l):
    r = random.random()
    #indexstr = "/index.html?ok=" + str(r)
    indexstr = "/index.html"
    l.client.get(indexstr,headers={"User-Agent":"locust"},name="/index.html?ok=[random]")


class UserBehavior(TaskSet):
    tasks = {index: 1}

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    wait_time = between(0.1,0.2)
