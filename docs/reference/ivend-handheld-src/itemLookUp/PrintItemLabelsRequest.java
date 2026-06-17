package com.citixsys.ivend_handheld.itemLookUp;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public class PrintItemLabelsRequest {

    @SerializedName("EnterpriseName")
    @Expose
    private String enterpriseName;

    @SerializedName("GenerateIntegrationEvent")
    @Expose
    private Boolean generateIntegrationEvent;

    @SerializedName("HandheldDeviceId")
    @Expose
    private String handheldDeviceId;

    @SerializedName("Key")
    @Expose
    private String key;

    @SerializedName("Message")
    @Expose
    private String message;

    @SerializedName("Price")
    @Expose
    private double price;

    @SerializedName("ProductId")
    @Expose
    private String productId;

    @SerializedName("QuantityToPrint")
    @Expose
    private double quantityToPrint;

    @SerializedName("UPC")
    @Expose
    private String uPC;

    @SerializedName("UserFieldsList")
    @Expose
    private List<UserFieldsList> userFieldsList = null;

    @SerializedName("WarehouseId")
    @Expose
    private String warehouseId;

    public String getMessage() {
        return this.message;
    }

    public void setMessage(String str) {
        this.message = str;
    }

    public Boolean getGenerateIntegrationEvent() {
        return this.generateIntegrationEvent;
    }

    public void setGenerateIntegrationEvent(Boolean bool) {
        this.generateIntegrationEvent = bool;
    }

    public String getEnterpriseName() {
        return this.enterpriseName;
    }

    public void setEnterpriseName(String str) {
        this.enterpriseName = str;
    }

    public List<UserFieldsList> getUserFieldsList() {
        return this.userFieldsList;
    }

    public void setUserFieldsList(List<UserFieldsList> list) {
        this.userFieldsList = list;
    }

    public String getKey() {
        return this.key;
    }

    public void setKey(String str) {
        this.key = str;
    }

    public String getHandheldDeviceId() {
        return this.handheldDeviceId;
    }

    public void setHandheldDeviceId(String str) {
        this.handheldDeviceId = str;
    }

    public double getPrice() {
        return this.price;
    }

    public void setPrice(double d) {
        this.price = d;
    }

    public double getQuantityToPrint() {
        return this.quantityToPrint;
    }

    public void setQuantityToPrint(double d) {
        this.quantityToPrint = d;
    }

    public String getUPC() {
        return this.uPC;
    }

    public void setUPC(String str) {
        this.uPC = str;
    }

    public String getWarehouseId() {
        return this.warehouseId;
    }

    public void setWarehouseId(String str) {
        this.warehouseId = str;
    }

    public String getProductId() {
        return this.productId;
    }

    public void setProductId(String str) {
        this.productId = str;
    }

    class UserFieldsList {

        @SerializedName("FieldName")
        @Expose
        private String fieldName;

        @SerializedName("FieldType")
        @Expose
        private Integer fieldType;

        @SerializedName("FieldValue")
        @Expose
        private String fieldValue;

        UserFieldsList(PrintItemLabelsRequest printItemLabelsRequest) {
        }

        public String getFieldName() {
            return this.fieldName;
        }

        public void setFieldName(String str) {
            this.fieldName = str;
        }

        public String getFieldValue() {
            return this.fieldValue;
        }

        public void setFieldValue(String str) {
            this.fieldValue = str;
        }

        public Integer getFieldType() {
            return this.fieldType;
        }

        public void setFieldType(Integer num) {
            this.fieldType = num;
        }
    }
}
