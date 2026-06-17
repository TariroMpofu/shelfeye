package com.citixsys.ivend_handheld.utility.commonDataModel;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public class ItemPrice {

    @SerializedName("CustomerId")
    @Expose
    private String customerId;

    @SerializedName("Discount")
    @Expose
    private Double discount;

    @SerializedName("DiscountType")
    @Expose
    private Integer discountType;

    @SerializedName("EnterpriseName")
    @Expose
    private String enterpriseName;

    @SerializedName("GenerateIntegrationEvent")
    @Expose
    private Boolean generateIntegrationEvent;

    @SerializedName("ItemPrice")
    @Expose
    private Double itemPrice;

    @SerializedName("Key")
    @Expose
    private Integer key;

    @SerializedName("Message")
    @Expose
    private String message;

    @SerializedName("ProductId")
    @Expose
    private String productId;

    @SerializedName("Quantity")
    @Expose
    private Double quantity;

    @SerializedName("StoreId")
    @Expose
    private String storeId;

    @SerializedName("UOMId")
    @Expose
    private String uOMId;

    @SerializedName("UserFieldsList")
    @Expose
    private List<UserFieldsList> userFieldsList = null;

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

    public Integer getKey() {
        return this.key;
    }

    public void setKey(Integer num) {
        this.key = num;
    }

    public String getProductId() {
        return this.productId;
    }

    public void setProductId(String str) {
        this.productId = str;
    }

    public String getStoreId() {
        return this.storeId;
    }

    public void setStoreId(String str) {
        this.storeId = str;
    }

    public String getCustomerId() {
        return this.customerId;
    }

    public void setCustomerId(String str) {
        this.customerId = str;
    }

    public Double getQuantity() {
        return this.quantity;
    }

    public void setQuantity(Double d) {
        this.quantity = d;
    }

    public String getUOMId() {
        return this.uOMId;
    }

    public void setUOMId(String str) {
        this.uOMId = str;
    }

    public Double getItemPrice() {
        return this.itemPrice;
    }

    public void setItemPrice(Double d) {
        this.itemPrice = d;
    }

    public Double getDiscount() {
        return this.discount;
    }

    public void setDiscount(Double d) {
        this.discount = d;
    }

    public Integer getDiscountType() {
        return this.discountType;
    }

    public void setDiscountType(Integer num) {
        this.discountType = num;
    }

    public class UserFieldsList {

        @SerializedName("FieldName")
        @Expose
        private String fieldName;

        @SerializedName("FieldType")
        @Expose
        private Integer fieldType;

        @SerializedName("FieldValue")
        @Expose
        private String fieldValue;

        public UserFieldsList(ItemPrice itemPrice) {
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
