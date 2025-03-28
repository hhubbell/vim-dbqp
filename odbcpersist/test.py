#
#
#

import contextlib
import multiprocessing
import time
import controller
import server


class ConnMock():
    @contextlib.contextmanager
    def cursor(self, *args, **kwargs):
        return CurMock()

class CurMock():
    def __init__(self, *args, **kwargs):
        self.state = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.state < 1:
            self.state += 1
            return self
        else:
            raise StopIteration

    def __enter__(self):
        return self

    def __exit__(self, *args, **kwargs):
        pass

    def execute(self, *args, **kwargs):
        pass

    def fetch_all(self, *args, **kwargs):
        pass

    def throw(self, *args, **kwargs):
        pass


if __name__ == '__main__':
    """
    d = multiprocessing.Process(target=server.daemon, args=(ConnMock(),))
    d.start()
    time.sleep(3)
    #c = multiprocessing.Process(target=controller.send_query, args=("select * from foo;",))
    pid = controller.get_pid()
    print('pid', pid)
    time.sleep(1)
    
    print('test kill')
    controller.kill()
    time.sleep(1)

    d.join()
    """

    d = multiprocessing.Process(target=server.start_daemon, args=("sqlite://tst.db", 10))
    d.start()
    time.sleep(3)

    controller.send_query("select * from foo limit 10")

