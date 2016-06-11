package java.lang;

import com.facebook.infer.models.InferBuiltins;
import com.facebook.infer.models.InferUndefined;
import com.facebook.infer.annotation.PrivacySource;

import java.io.Serializable;
import java.lang.CharSequence;

public class StringBuilder implements Serializable, CharSequence {

    private String input;

    public StringBuilder() {}

    public StringBuilder(CharSequence charSequence) {}

    public StringBuilder(int capacity) {}

    public StringBuilder(String str) {
		this.input = str;
    }
    
    public StringBuilder append(String input) {
	if (InferUndefined.boolean_undefined()) {
	    this.input = input;
	}

	return this;
    }

    public String toString() {
	return this.input;
    }

    public char charAt(int index) {
	return InferUndefined.char_undefined();
    }

    public CharSequence subSequence(int start, int end) {
	return this;
    }

    public int length() {
	return InferUndefined.int_undefined();
    }
    
}
