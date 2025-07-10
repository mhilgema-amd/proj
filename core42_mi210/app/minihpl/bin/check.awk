BEGIN {
    overall_status = 0 # 0 for success, 1 for failure
}

/Score:/ {
    device_id = $2
    score_str = $4
    gflops = score_str

    # Convert scientific notation to a number for comparison
    # This handles the 'e+04' part
    if (gflops ~ /[eE][+\-][0-9]+/) {
        gflops_val = gflops
    } else {
        gflops_val = gflops
    }

    status = $NF # Get the last field, which should be "PASS" or "FAIL"

    if (status == "PASSED") { 
        if (gflops_val > 1.7e+04) {
            print "Device " device_id ": PASSED and performance meets requirement (" gflops " GFLOPS)"
        } else {
            print "Device " device_id ": FAILED due to performance below requirement (" gflops " GFLOPS)"
            overall_status = 1
        }
    } else {
        if (gflops_val > 1.7e+04) {
            print "Device " device_id ": FAILED due to status (" status ")"
        } else {
            print "Device " device_id ": FAILED due to status (" status ") AND performance (" gflops " GFLOPS)"
        }
        overall_status = 1
    }
}

END {
    if (overall_status == 0)  {
        print "YES"
    } else {
        print "NO"
    }
    exit overall_status
}
