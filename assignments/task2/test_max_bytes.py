import unittest
import sys
from max_bytes import max_bytes


class TestMaxBytes(unittest.TestCase):
    
    @classmethod
    def setUpClass(cls):
        """Print test suite header"""
        print("\n" + "="*60)
        print("🧪 RUNNING MAX_BYTES FUNCTION TEST SUITE")
        print("="*60)
    
    def setUp(self):
        """Store test start info"""
        self.test_name = self._testMethodName.replace('_', ' ').title()
        self.test_passed = True
    
    def tearDown(self):
        """Print test result in one line"""
        import sys
        if sys.exc_info()[0] is None:
            status = "✅ PASSED"
        else:
            status = "❌ FAILED"
            self.test_passed = False
        
        # Print in one line format
        if hasattr(self, 'result_info'):
            print(f"🔬 {self.test_name:<25} | Expected: {self.result_info['expected']:<6} | Got: {self.result_info['actual']:<6} | {status}")
        else:
            print(f"🔬 {self.test_name:<25} | {status}")
    
    def test_simple_case(self):
        """Test basic functionality with several events"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 2, "bytes": 50},
            {"timestamp": 3, "bytes": 300},
            {"timestamp": 6, "bytes": 10},
            {"timestamp": 7, "bytes": 30},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 450, 'actual': result}
        self.assertEqual(result, 450)
    
    def test_single_event(self):
        """Test with a single event"""
        events = [{"timestamp": 1, "bytes": 100}]
        result = max_bytes(events)
        self.result_info = {'expected': 100, 'actual': result}
        self.assertEqual(result, 100)
    
    def test_no_overlap(self):
        """Test events with no overlap in 5-second window"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 10, "bytes": 200},
            {"timestamp": 20, "bytes": 300},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 300, 'actual': result}
        self.assertEqual(result, 300)
    
    def test_all_in_window(self):
        """Test when all events fit in one window"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 2, "bytes": 200},
            {"timestamp": 3, "bytes": 150},
            {"timestamp": 4, "bytes": 50},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 500, 'actual': result}
        self.assertEqual(result, 500)
    
    def test_unsorted_events(self):
        """Test with unsorted events"""
        events = [
            {"timestamp": 5, "bytes": 100},
            {"timestamp": 1, "bytes": 200},
            {"timestamp": 3, "bytes": 150},
            {"timestamp": 2, "bytes": 50},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 500, 'actual': result}
        self.assertEqual(result, 500)
    
    def test_sliding_window(self):
        """Test sliding window with overlap"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 3, "bytes": 200},
            {"timestamp": 5, "bytes": 300},
            {"timestamp": 7, "bytes": 400},
            {"timestamp": 9, "bytes": 150},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 900, 'actual': result}
        self.assertEqual(result, 900)
    
    def test_empty_list(self):
        """Test with empty list"""
        events = []
        result = max_bytes(events)
        self.result_info = {'expected': 0, 'actual': result}
        self.assertEqual(result, 0)
    
    def test_boundary_case(self):
        """Test boundary case - exactly 5 seconds"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 5, "bytes": 200},
            {"timestamp": 6, "bytes": 300},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 500, 'actual': result}
        self.assertEqual(result, 500)
    
    def test_large_dataset(self):
        """Test with large dataset (same as main file)"""
        events = [
            {"timestamp": 45, "bytes": 280},
            {"timestamp": 3, "bytes": 300},
            {"timestamp": 67, "bytes": 150},
            {"timestamp": 12, "bytes": 100},
            {"timestamp": 89, "bytes": 420},
            {"timestamp": 23, "bytes": 10},
            {"timestamp": 56, "bytes": 250},
            {"timestamp": 1, "bytes": 50},
            {"timestamp": 78, "bytes": 320},
            {"timestamp": 34, "bytes": 180},
            {"timestamp": 91, "bytes": 380},
            {"timestamp": 15, "bytes": 75},
            {"timestamp": 42, "bytes": 290},
            {"timestamp": 8, "bytes": 160},
            {"timestamp": 73, "bytes": 110},
            {"timestamp": 29, "bytes": 240},
            {"timestamp": 61, "bytes": 220},
            {"timestamp": 7, "bytes": 60},
            {"timestamp": 85, "bytes": 350},
            {"timestamp": 36, "bytes": 95},
            {"timestamp": 52, "bytes": 270},
            {"timestamp": 19, "bytes": 130},
            {"timestamp": 74, "bytes": 190},
            {"timestamp": 41, "bytes": 310},
            {"timestamp": 6, "bytes": 80},
            {"timestamp": 68, "bytes": 200},
            {"timestamp": 25, "bytes": 170},
            {"timestamp": 83, "bytes": 360},
            {"timestamp": 14, "bytes": 120},
            {"timestamp": 57, "bytes": 260},
            {"timestamp": 92, "bytes": 400},
            {"timestamp": 38, "bytes": 210},
            {"timestamp": 11, "bytes": 90},
            {"timestamp": 69, "bytes": 330},
            {"timestamp": 26, "bytes": 140},
            {"timestamp": 84, "bytes": 370},
            {"timestamp": 47, "bytes": 230},
            {"timestamp": 2, "bytes": 70},
            {"timestamp": 71, "bytes": 340},
            {"timestamp": 33, "bytes": 155},
            {"timestamp": 58, "bytes": 275},
            {"timestamp": 16, "bytes": 105},
            {"timestamp": 79, "bytes": 315},
            {"timestamp": 44, "bytes": 285},
            {"timestamp": 9, "bytes": 85},
            {"timestamp": 65, "bytes": 325},
            {"timestamp": 28, "bytes": 165},
            {"timestamp": 81, "bytes": 355},
            {"timestamp": 53, "bytes": 245},
            {"timestamp": 18, "bytes": 115},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 1435, 'actual': result}
        self.assertEqual(result, 1435)
    
    def test_identical_timestamps(self):
        """Test with identical timestamps"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 1, "bytes": 200},
            {"timestamp": 1, "bytes": 150},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 450, 'actual': result}
        self.assertEqual(result, 450)
    
    def test_zero_bytes(self):
        """Test with zero bytes"""
        events = [
            {"timestamp": 1, "bytes": 0},
            {"timestamp": 2, "bytes": 100},
            {"timestamp": 3, "bytes": 0},
        ]
        result = max_bytes(events)
        self.result_info = {'expected': 100, 'actual': result}
        self.assertEqual(result, 100)

    @classmethod
    def tearDownClass(cls):
        """Print test suite footer"""
        print("\n" + "="*60)
        print("🎉 TEST SUITE COMPLETED")
        print("="*60)


if __name__ == '__main__':
    # Custom test runner for beautiful output
    class ColorTestResult(unittest.TextTestResult):
        def addSuccess(self, test):
            super().addSuccess(test)
            
        def addError(self, test, err):
            super().addError(test, err)
            
        def addFailure(self, test, err):
            super().addFailure(test, err)

    # Run tests with custom formatting
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromTestCase(TestMaxBytes)
    
    runner = unittest.TextTestRunner(
        stream=sys.stdout,
        verbosity=0,
        resultclass=ColorTestResult
    )
    
    print("🚀 Starting test execution...")
    result = runner.run(suite)
    
    # Print summary
    print(f"\n📊 SUMMARY:")
    print(f"   Tests run: {result.testsRun}")
    print(f"   Failures: {len(result.failures)}")
    print(f"   Errors: {len(result.errors)}")
    
    if result.failures:
        print(f"\n❌ FAILED TESTS:")
        for test, traceback in result.failures:
            print(f"   - {test}")
    
    if result.errors:
        print(f"\n💥 ERROR TESTS:")
        for test, traceback in result.errors:
            print(f"   - {test}")
    
    if result.wasSuccessful():
        print(f"\n🎊 ALL TESTS PASSED! 🎊")
    else:
        print(f"\n⚠️  SOME TESTS FAILED")
        sys.exit(1)
