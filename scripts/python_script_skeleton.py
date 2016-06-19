import logging, sys, os, re
logger = logging.getLogger(__name__)

PARAMS = {
  "" : "",
}

if __name__ == '__main__':
  logging.basicConfig(level=logging.DEBUG,
                     format='%(asctime)s [%(levelname) 5.5s] %(filename)s::%(funcName)s-%(lineno)d  %(message)s')
  logger.info("Input parameters : \n%s", "\n".join(sorted(" - %s : %r" % (k,v) for k,v in PARAMS.items())) )

