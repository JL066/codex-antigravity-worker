#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# codex-antigravity-worker Smoke Test
# Creates an ephemeral, temporary Git fixture and runs a scoped test.
# ==============================================================================

TMP_DIR="$(mktemp -d /tmp/codex-agy-smoke-XXXXXX)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "=== Running Codex Antigravity Smoke Test ==="
echo "Creating ephemeral fixture at: ${TMP_DIR}"

cd "${TMP_DIR}"
git init -q
git config user.name "SmokeTest"
git config user.email "smoketest@example.com"

# 1. Create a buggy module
cat << 'EOF' > calculator.py
def calculate_discount(price: float, discount_percent: float) -> float:
    """Calculate the final price after discount.
    
    Bug: It adds the discount instead of subtracting it.
    """
    discount_amount = price * (discount_percent / 100.0)
    return price + discount_amount
EOF

# 2. Create the validation test
cat << 'EOF' > test_calculator.py
from calculator import calculate_discount

def test_calculate_discount():
    assert calculate_discount(100.0, 20.0) == 80.0, f"Expected 80.0, got {calculate_discount(100.0, 20.0)}"
    assert calculate_discount(50.0, 10.0) == 45.0, f"Expected 45.0, got {calculate_discount(50.0, 10.0)}"

if __name__ == "__main__":
    test_calculate_discount()
    print("ALL TESTS PASSED")
EOF

git add calculator.py test_calculator.py
git commit -q -m "Initial buggy fixture"

echo "Fixture ready. Verifying that test initially fails..."
if python3 test_calculator.py >/dev/null 2>&1; then
    echo "Error: Test was expected to fail initially!"
    exit 1
fi
echo "Initial test failed as expected."

# 3. Check for Codex CLI
CODEX_BIN=""
if command -v codex >/dev/null 2>&1; then
    CODEX_BIN="$(command -v codex)"
elif [[ -x "/Applications/ChatGPT.app/Contents/Resources/codex" ]]; then
    CODEX_BIN="/Applications/ChatGPT.app/Contents/Resources/codex"
fi

if [[ -n "${CODEX_BIN}" ]]; then
    echo "Found Codex CLI at: ${CODEX_BIN}"

    EXTRA_FLAGS=()
    if [[ "${CODEX_UNSAFE_SMOKE:-0}" == "1" ]]; then
        echo "Notice: CODEX_UNSAFE_SMOKE=1 enabled; running with bypassed approvals and sandbox."
        EXTRA_FLAGS+=("--dangerously-bypass-approvals-and-sandbox")
    else
        echo "Running smoke test with standard Codex approvals and sandbox policy."
        echo "Note: If your environment requires unattended execution without interactive prompts,"
        echo "      you can explicitly opt in using: CODEX_UNSAFE_SMOKE=1 ./scripts/smoke-test.sh"
    fi

    echo "Running end-to-end task through Codex..."
    "${CODEX_BIN}" exec "${EXTRA_FLAGS[@]}" -C "${TMP_DIR}" \
        "请调用 agy MCP 工具中的 agy_run_sync，指定 model 为 gemini-3.8-flash-medium，在当前目录修复 calculator.py 的折扣计算 bug 并运行现有测试验证。" </dev/null || {
            echo ""
            echo "Smoke test execution finished with non-zero exit code."
            if [[ "${CODEX_UNSAFE_SMOKE:-0}" != "1" ]]; then
                echo "Tip: If execution was blocked by approval/sandbox prompts in non-interactive mode,"
                echo "     try: CODEX_UNSAFE_SMOKE=1 ./scripts/smoke-test.sh"
            fi
            exit 1
        }
else
    echo "Codex CLI not detected in standard locations. Please run the task from within the Codex UI."
fi

# 4. Verify the fix
echo "Verifying test suite results in fixture..."
cd "${TMP_DIR}"
python3 test_calculator.py

echo ""
echo "=== Smoke Test PASSED Successfully! ==="
