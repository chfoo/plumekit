package plumekit;

import utest.Runner;
import utest.ui.Report;


class TestAll {
    public static function main() {
        var runner = new Runner();

        addEventLoopCases(runner);
        addNetCases(runner);
        runner.addCases(plumekit.test.netdata);
        runner.addCases(plumekit.test.stream);
        runner.addCases(plumekit.test.text);
        runner.addCases(plumekit.test.www);

        Report.create(runner);
        runner.run();
    }

    static function addEventLoopCases(runner:Runner) {
        #if sys
        runner.addCase(new plumekit.test.eventloop.TestSelectConnectionServer());
        #end
    }

    static function addNetCases(runner:Runner) {
        #if sys
        runner.addCase(new plumekit.test.net.TestSelectConnection());
        runner.addCase(new plumekit.test.net.TestSelectSocketStream());
        #end
    }
}
