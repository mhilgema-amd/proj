BEGIN {
    overall_status = 0 # 0 for success, 1 for failure
}

/Score:/ {
    device_id = $2
    score_str = $7
    bw = score_str

    # Convert scientific notation to a number for comparison
    # This handles the 'e+04' part
    if (bv ~ /[eE][+\-][0-9]+/) {
        bw_val = bw
    } else {
        bw_val = bw
    }

    status = $NF # Get the last field, which should be "PASS" or "FAIL"

    if (status == "PASSED") { 
        if (bw_val > 1700) {
            print "Device " device_id ": PASSED and performance meets requirement (" bw " GB/s)"
        } else {
            print "Device " device_id ": FAILED due to performance below requirement (" bw " GB/s)"
            overall_status = 1
        }
    } else {
        if (bw_val > 1700) {
            print "Device " device_id ": FAILED due to status (" status ")"
        } else {
            print "Device " device_id ": FAILED due to status (" status ") AND performance (" bw " GB/s)"
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
