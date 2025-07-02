import unittest
import sys
from app import max_bytes


class TestMaxBytes(unittest.TestCase):
    
    @classmethod
    def setUpClass(cls):
        """Print test suite header"""
        print("\n" + "="*60)
        print("🧪 RUNNING MAX_BYTES FUNCTION TEST SUITE")
        print("="*60)
    
    def setUp(self):
        """Print test start indicator"""
        test_name = self._testMethodName.replace('_', ' ').title()
        print(f"\n🔬 Testing: {test_name}")
    
    def tearDown(self):
        """Print test result"""
        if hasattr(self, '_outcome'):
            if self._outcome.errors or self._outcome.failures:
                print("❌ FAILED")
            else:
                print("✅ PASSED")
    
    def test_simple_case(self):
        """Test basic functionality with several events"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 2, "bytes": 50},
            {"timestamp": 3, "bytes": 300},
            {"timestamp": 6, "bytes": 10},
            {"timestamp": 7, "bytes": 30},
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 2, "bytes": 50},
            {"timestamp": 3, "bytes": 300},
            {"timestamp": 6, "bytes": 10},
            {"timestamp": 7, "bytes": 30},
        ]
        # Maximum in window [1,2,3] = 100+50+300 = 450
        result = max_bytes(events)
        print(f"   Expected: 450, Got: {result}")
        self.assertEqual(result, 450)
    
    def test_single_event(self):
        """Test with a single event"""
        events = [{"timestamp": 1, "bytes": 100}]
        result = max_bytes(events)
        print(f"   Expected: 100, Got: {result}")
        self.assertEqual(result, 100)
    
    def test_no_overlap(self):
        """Test events with no overlap in 5-second window"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 10, "bytes": 200},
            {"timestamp": 20, "bytes": 300},
        ]
        # Each event in its own window
        result = max_bytes(events)
        print(f"   Expected: 300, Got: {result}")
        self.assertEqual(result, 300)
    
    def test_all_in_window(self):
        """Test when all events fit in one window"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 2, "bytes": 200},
            {"timestamp": 3, "bytes": 150},
            {"timestamp": 4, "bytes": 50},
        ]
        # All events in window [1-4] = 100+200+150+50 = 500
        result = max_bytes(events)
        print(f"   Expected: 500, Got: {result}")
        self.assertEqual(result, 500)
    
    def test_unsorted_events(self):
        """Test with unsorted events"""
        events = [
            {"timestamp": 5, "bytes": 100},
            {"timestamp": 1, "bytes": 200},
            {"timestamp": 3, "bytes": 150},
            {"timestamp": 2, "bytes": 50},
        ]
        # After sorting: [1,2,3,5] - all in one window (diff 1-5 = 4 < 5)
        # Sum: 200+50+150+100 = 500
        result = max_bytes(events)
        print(f"   Expected: 500, Got: {result}")
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
        # Window [3,5,7] = 200+300+400 = 900 (maximum)
        result = max_bytes(events)
        print(f"   Expected: 900, Got: {result}")
        self.assertEqual(result, 900)
    
    def test_empty_list(self):
        """Test with empty list"""
        events = []
        result = max_bytes(events)
        print(f"   Expected: 0, Got: {result}")
        self.assertEqual(result, 0)
    
    def test_boundary_case(self):
        """Test boundary case - exactly 5 seconds"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 5, "bytes": 200},
            {"timestamp": 6, "bytes": 300},
        ]
        # Events at timestamp 1 and 5 ARE in one window (diff = 4 < 5)
        # Events at timestamp 1 and 6 are NOT in one window (diff = 5 >= 5)
        # Maximum is either 100, 200, 300, or 200+300=500
        result = max_bytes(events)
        print(f"   Expected: 500, Got: {result}")
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
        # Expected result: 1435 (window [81,83,84,85])
        result = max_bytes(events)
        print(f"   Expected: 1435, Got: {result}")
        print(f"   Optimal window: timestamps 81-85 (355+360+370+350)")
        self.assertEqual(result, 1435)
    
    def test_identical_timestamps(self):
        """Test with identical timestamps"""
        events = [
            {"timestamp": 1, "bytes": 100},
            {"timestamp": 1, "bytes": 200},
            {"timestamp": 1, "bytes": 150},
        ]
        # All events at same timestamp = 100+200+150 = 450
        result = max_bytes(events)
        print(f"   Expected: 450, Got: {result}")
        self.assertEqual(result, 450)
    
    def test_zero_bytes(self):
        """Test with zero bytes"""
        events = [
            {"timestamp": 1, "bytes": 0},
            {"timestamp": 2, "bytes": 100},
            {"timestamp": 3, "bytes": 0},
        ]
        # Maximum in window [1,2,3] = 0+100+0 = 100
        result = max_bytes(events)
        print(f"   Expected: 100, Got: {result}")
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
