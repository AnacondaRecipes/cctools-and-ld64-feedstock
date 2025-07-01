import os
import subprocess
import sys
from tempfile import TemporaryDirectory

def test_duplicate_rpaths():
    """Test that ld64 warns about and ignores duplicate -rpath arguments."""
    
    # Find the cross-platform ld64 binary
    prefix = os.environ.get('PREFIX', '/usr/local')
    
    # Try to find the ld64 binary - it could be named differently depending on the platform
    possible_ld_names = [
        'x86_64-apple-darwin13.4.0-ld',
        'arm64-apple-darwin20.0.0-ld', 
        'ld'
    ]
    
    ld_path = None
    for ld_name in possible_ld_names:
        candidate_path = os.path.join(prefix, 'bin', ld_name)
        if os.path.exists(candidate_path):
            ld_path = candidate_path
            break
    
    if not ld_path:
        print("ERROR: Could not find ld64 binary")
        return False
    
    print(f"Using ld64 binary: {ld_path}")
    
    with TemporaryDirectory() as tmpdir:
        # Create a simple C source file
        src_path = os.path.join(tmpdir, "test.c")
        with open(src_path, "w") as f:
            f.write("int main(void) { return 0; }\n")
        
        # Create object file
        obj_path = os.path.join(tmpdir, "test.o")
        compile_cmd = [
            'clang', '-c', src_path, '-o', obj_path
        ]
        
        try:
            subprocess.run(compile_cmd, check=True, capture_output=True)
        except subprocess.CalledProcessError as e:
            print(f"ERROR: Failed to compile test.c: {e}")
            return False
        
        # Create output executable path
        exe_path = os.path.join(tmpdir, "test_exe")
        
        # Test duplicate rpaths - this should trigger the warning with the patch
        rpath1 = "/some/test/path"
        rpath2 = "/another/test/path"
        
        link_cmd = [
            ld_path,
            obj_path,
            '-o', exe_path,
            '-lSystem',
            '-rpath', rpath1,
            '-rpath', rpath2,
            '-rpath', rpath1,  # This is the duplicate that should trigger warning
            '-arch', 'x86_64' if 'x86_64' in ld_path else 'arm64'
        ]
        
        print("Running link command with duplicate rpaths:")
        print(" ".join(link_cmd))
        
        try:
            result = subprocess.run(link_cmd, capture_output=True, text=True)
            
            print(f"Return code: {result.returncode}")
            print(f"Stdout: {result.stdout}")
            print(f"Stderr: {result.stderr}")
            
            # Check if linking succeeded
            if result.returncode != 0:
                print(f"ERROR: Linking failed: {result.stderr}")
                return False
            
            # With the patch, we should see a warning about duplicate rpath
            expected_warning = f"ld: warning: duplicate -rpath '{rpath1}' ignored"
            
            if expected_warning in result.stderr:
                print("SUCCESS: Found expected duplicate rpath warning")
                return True
            else:
                print("ERROR: Expected duplicate rpath warning not found")
                print(f"Expected: {expected_warning}")
                print(f"Got stderr: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"ERROR: Exception during linking: {e}")
            return False

def main():
    success = test_duplicate_rpaths()
    if not success:
        print("Test FAILED - duplicate rpath patch may not be working")
        sys.exit(1)
    else:
        print("Test PASSED - duplicate rpath patch is working")
        sys.exit(0)

if __name__ == "__main__":
    main() 