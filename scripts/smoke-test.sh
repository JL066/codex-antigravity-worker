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
    echo "Running end-to-end task through Codex..."
    "${CODEX_BIN}" exec --dangerously-bypass-approvals-and-sandbox -C "${TMP_DIR}" \
        "请调用 agy MCP 工具中的 agy_run_sync，指定 model 为 gemini-3.7-flash-high，在当前目录修复 calculator.py 的折扣计算 bug 并运行现有测试验证。" </dev/null
else
    echo "Codex CLI not detected in standard locations. Please run the task from within the Codex UI."
fi

# 4. Verify the fix
echo "Verifying test suite results in fixture..."
cd "${TMP_DIR}"
python3 test_calculator.py

echo ""
echo "=== Smoke Test PASSED Successfully! ==="
