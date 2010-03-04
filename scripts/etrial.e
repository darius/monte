#!/usr/bin/env rune

def makeTestResults := <import:com.twistedmatrix.eunit.makeTestResults>;
def makeTestLoader := <import:com.twistedmatrix.eunit.makeTestLoader>;
def makeTestSuite := <import:com.twistedmatrix.eunit.makeTestSuite>;



def getProblemStackAndMessage :=
    if (privilegedScope.maps("lisp")) {
       def Throwable := <import:org.cubik.cle.prim.Throwable>
      def formatCLBacktrace(p :Throwable) {
       def stack := privilegedScope["lisp"]["E.ELIB", "LOCAL-THROW-SEALED-BOX-BACKTRACE"].getFunction()(p)
       return privilegedScope["lisp"]["CL-USER", "FORMAT"].getFunction()(null, "~A", stack)
       }
        def getProblemStackAndMessage(p) {
            #can't say 'lisp' because then this code wouldn't parse under EoJ
            return [formatCLBacktrace(p),
                   privilegedScope["lisp"]["E.ELIB",
                         "LOCAL-THROW-SEALED-BOX-VALUE"].getFunction()(
                             p:Throwable)]
        }
    } else {
        def getProblemStackAndMessage(p) {
            return [p.eStack(), p.leaf().getMessage()]
        }
    }

def runTest(testRunnable) {
  def results := makeTestResults(getProblemStackAndMessage)
  def res := testRunnable.run(results)
  for report in res.reportFailures() {
    stdout.println()
    stdout.println(report)
  }
  stdout.println(res.summary())

}
def testLoader := makeTestLoader(<file>);
def <test> {
  to get(testFQN) {
    def suite := makeTestSuite()
    for testCaseMaker in testLoader.loadTestCase(testFQN) {
      var testCase := testCaseMaker()
      for testName in testCase.collectTestMethods() {
        suite.add(testCase, testName)
        testCase := testCaseMaker()
      }
    }
    return suite
  }
}

def x := <test>[interp.getArgs()[0]]
runTest(x)




# def makeRunnerTest := <import:com.twistedmatrix.eunit.tests.testRunner>
# def suite2 := makeTestSuite()
# def results2 := makeTestResults()
# suite2.add(makeRunnerTest(), "test_runSuite")
# suite2.run(null, results).summary()

# Test List!!

# test runner
#  test discovery
#   retrieve tests by FQN
#    retrieve an emaker by FQN and run all the tests in the test suite in it
#    retrieve a package and collect all the emakers in it that return tests
#  updoc runner
#  updoc discovery