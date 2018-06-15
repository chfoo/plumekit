package plumekit;

import utest.Runner;
import utest.ui.Report;


class TestAll {
    public static function main() {
        var runner = new Runner();
        runner.addCases(plumekit.test);
        Report.create(runner);
        runner.run();
    }
}
