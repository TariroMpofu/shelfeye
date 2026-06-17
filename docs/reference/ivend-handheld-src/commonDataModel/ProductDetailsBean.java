package com.citixsys.ivend_handheld.utility.commonDataModel;

/* JADX INFO: loaded from: classes.dex */
public class ProductDetailsBean {
    private boolean allowFractionalQuantity;
    private String description;
    private String id;
    private int isGiftCertificate;
    private int isMatrixItem;
    private int isNonStock;
    private int itemManageType;
    private double price;
    private boolean purchasable;
    private String purchaseTaxCodeId;
    private double qty;
    private String searchBarcode;
    private String serialBatchNumber;
    private String uomGroupkey;
    private String uomId;

    public String getSearchBarcode() {
        return this.searchBarcode;
    }

    public void setSearchBarcode(String str) {
        this.searchBarcode = str;
    }

    public String getSerialBatchNumber() {
        return this.serialBatchNumber;
    }

    public void setSerialBatchNumber(String str) {
        this.serialBatchNumber = str;
    }

    public int getIsNonStock() {
        return this.isNonStock;
    }

    public void setIsNonStock(int i) {
        this.isNonStock = i;
    }

    public int getIsGiftCertificate() {
        return this.isGiftCertificate;
    }

    public void setIsGiftCertificate(int i) {
        this.isGiftCertificate = i;
    }

    public int getIsMatrixItem() {
        return this.isMatrixItem;
    }

    public void setIsMatrixItem(int i) {
        this.isMatrixItem = i;
    }

    public String getPurchaseTaxCodeId() {
        return this.purchaseTaxCodeId;
    }

    public void setPurchaseTaxCodeId(String str) {
        this.purchaseTaxCodeId = str;
    }

    public String getId() {
        return this.id;
    }

    public void setId(String str) {
        this.id = str;
    }

    public String getDescription() {
        return this.description;
    }

    public void setDescription(String str) {
        this.description = str;
    }

    public int getItemManageType() {
        return this.itemManageType;
    }

    public void setItemManageType(int i) {
        this.itemManageType = i;
    }

    public double getQty() {
        return this.qty;
    }

    public void setQty(double d) {
        this.qty = d;
    }

    public double getPrice() {
        return this.price;
    }

    public void setPrice(double d) {
        this.price = d;
    }

    public String getUomId() {
        return this.uomId;
    }

    public void setUomId(String str) {
        this.uomId = str;
    }

    public String getUomGroupkey() {
        return this.uomGroupkey;
    }

    public void setUomGroupkey(String str) {
        this.uomGroupkey = str;
    }

    public boolean isPurchasable() {
        return this.purchasable;
    }

    public void setPurchasable(boolean z) {
        this.purchasable = z;
    }

    public boolean isAllowFractionalQuantity() {
        return this.allowFractionalQuantity;
    }

    public void setAllowFractionalQuantity(boolean z) {
        this.allowFractionalQuantity = z;
    }
}
