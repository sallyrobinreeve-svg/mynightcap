import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { isValidOtp, maskPhone, toE164 } from "./phone.ts";

describe("toE164", () => {
  it("formats a UK number and strips the leading 0", () => {
    assert.equal(toE164("+44", "07123 456789"), "+447123456789");
  });

  it("formats a US number", () => {
    assert.equal(toE164("+1", "(415) 555-2671"), "+14155552671");
  });

  it("accepts a pasted international number regardless of dial code", () => {
    assert.equal(toE164("+1", "+44 7123 456789"), "+447123456789");
  });

  it("rejects numbers that are too short", () => {
    assert.equal(toE164("+44", "07123"), null);
  });

  it("rejects empty input", () => {
    assert.equal(toE164("+44", "   "), null);
  });
});

describe("isValidOtp", () => {
  it("accepts a 6-digit code", () => {
    assert.equal(isValidOtp("123456"), true);
  });

  it("rejects short or non-numeric codes", () => {
    assert.equal(isValidOtp("12345"), false);
    assert.equal(isValidOtp("12345a"), false);
  });
});

describe("maskPhone", () => {
  it("keeps the country prefix and last three digits", () => {
    assert.equal(maskPhone("+447123456789"), "+447••••••789");
  });
});
