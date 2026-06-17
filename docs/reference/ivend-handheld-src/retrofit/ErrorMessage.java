package com.citixsys.ivend_handheld.retrofit;

/* JADX INFO: loaded from: classes.dex */
public class ErrorMessage {
    private String Description;
    private String ExceptionType;
    private String Message;
    private String Source;

    public String getMessage() {
        return this.Message;
    }

    public void setMessage(String str) {
        this.Message = str;
    }

    public String getExceptionType() {
        return this.ExceptionType;
    }

    public void setExceptionType(String str) {
        this.ExceptionType = str;
    }

    public String getSource() {
        return this.Source;
    }

    public void setSource(String str) {
        this.Source = str;
    }

    public String getDescription() {
        return this.Description;
    }

    public void setDescription(String str) {
        this.Description = str;
    }
}
