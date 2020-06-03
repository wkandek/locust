import random
from locust import HttpUser, task, between
from locust.contrib.fasthttp import FastHttpUser

class QuickstartUser(FastHttpUser):
    wait_time = between(0.01, 0.01)

    @task
    def index_page(self):
        r = random.random()
        #indexstr = "/index.html?ok=" + str(r)
        indexstr = "/index.html"
        self.client.get(indexstr,headers={"User-Agent":"locust"})
