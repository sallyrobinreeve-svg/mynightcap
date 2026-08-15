import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { toFriendlyAuthMessage } from "./auth-errors.ts";
import { accountFallbackName, accountInitial } from "./account-identity.ts";

describe("toFriendlyAuthMessage", () => {
  it("explains missing phone accounts", () => {
    assert.equal(
      toFriendlyAuthMessage("Signups not allowed for otp"),
      "No account found for this number. Create an account first."
    );
  });

  it("explains expired codes", () => {
    assert.equal(
      toFriendlyAuthMessage("Token has expired or is invalid"),
      "That code is invalid or expired. Request a new one."
    );
  });
});

describe("account identity", () => {
  it("prefers phone over email", () => {
    assert.equal(
      accountFallbackName({ phone: "+447123456789", email: "you@example.com" }),
      "+447123456789"
    );
  });

  it("uses the last phone digit for an avatar initial", () => {
    assert.equal(accountInitial({ phone: "+447123456789" }), "9");
  });
});
