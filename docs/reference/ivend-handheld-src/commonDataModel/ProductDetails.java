package com.citixsys.ivend_handheld.utility.commonDataModel;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public class ProductDetails {

    @SerializedName("AllowFractionalQuantity")
    @Expose
    private Boolean allowFractionalQuantity;

    @SerializedName("AllowZeroPrice")
    @Expose
    private Boolean allowZeroPrice;

    @SerializedName("AlternateUPCCodes")
    @Expose
    private String alternateUPCCodes;

    @SerializedName("Attributes")
    @Expose
    private String attributes;

    @SerializedName("AutoGenerateChildItemDefinition")
    @Expose
    private Boolean autoGenerateChildItemDefinition;

    @SerializedName("AutoSelectSerialBatchType")
    @Expose
    private Integer autoSelectSerialBatchType;

    @SerializedName("BarCodeMaskId")
    @Expose
    private String barCodeMaskId;

    @SerializedName("BasePrice")
    @Expose
    private Double basePrice;

    @SerializedName("CanLayaway")
    @Expose
    private Boolean canLayaway;

    @SerializedName("CanOrder")
    @Expose
    private Boolean canOrder;

    @SerializedName("CanRefundExpiredItem")
    @Expose
    private Boolean canRefundExpiredItem;

    @SerializedName("CanSellExpiredItem")
    @Expose
    private Boolean canSellExpiredItem;

    @SerializedName("Comment")
    @Expose
    private String comment;

    @SerializedName("Cost")
    @Expose
    private Double cost;

    @SerializedName("CostingMethod")
    @Expose
    private Integer costingMethod;

    @SerializedName("CostingSubMethod")
    @Expose
    private Integer costingSubMethod;

    @SerializedName("DefaultQuantity")
    @Expose
    private Double defaultQuantity;

    @SerializedName("Description")
    @Expose
    private String description;

    @SerializedName("DiscountsAllowed")
    @Expose
    private Boolean discountsAllowed;

    @SerializedName("EnterpriseName")
    @Expose
    private String enterpriseName;

    @SerializedName("ExternalLink")
    @Expose
    private String externalLink;

    @SerializedName("GenerateIntegrationEvent")
    @Expose
    private Boolean generateIntegrationEvent;

    @SerializedName("GiftCertificateType")
    @Expose
    private Integer giftCertificateType;

    @SerializedName("HasAlternateProducts")
    @Expose
    private Boolean hasAlternateProducts;

    @SerializedName("HasPackageGroup")
    @Expose
    private Boolean hasPackageGroup;

    @SerializedName("HasUpsells")
    @Expose
    private Boolean hasUpsells;

    @SerializedName("Id")
    @Expose
    private String id;

    @SerializedName("IgnoreDiscountItemsForSaleDiscount")
    @Expose
    private Boolean ignoreDiscountItemsForSaleDiscount;

    @SerializedName("ImageLocation")
    @Expose
    private String imageLocation;

    @SerializedName("InventoryUOMId")
    @Expose
    private String inventoryUOMId;

    @SerializedName("IsAssembly")
    @Expose
    private Boolean isAssembly;

    @SerializedName("IsBatchTracked")
    @Expose
    private Boolean isBatchTracked;

    @SerializedName("IsDynamicAssembly")
    @Expose
    private Boolean isDynamicAssembly;

    @SerializedName("IsEBTItem")
    @Expose
    private Boolean isEBTItem;

    @SerializedName("IsExchangable")
    @Expose
    private Boolean isExchangable;

    @SerializedName("IsGiftCertificate")
    @Expose
    private Boolean isGiftCertificate;

    @SerializedName("IsInclusiveTaxed")
    @Expose
    private Boolean isInclusiveTaxed;

    @SerializedName("IsKit")
    @Expose
    private Boolean isKit;

    @SerializedName("IsMatrixChildItem")
    @Expose
    private Boolean isMatrixChildItem;

    @SerializedName("IsMatrixItem")
    @Expose
    private Boolean isMatrixItem;

    @SerializedName("IsNonStock")
    @Expose
    private Boolean isNonStock;

    @SerializedName("IsOnHold")
    @Expose
    private Boolean isOnHold;

    @SerializedName("IsOpenDescription")
    @Expose
    private Boolean isOpenDescription;

    @SerializedName("IsOpenPrice")
    @Expose
    private Boolean isOpenPrice;

    @SerializedName("IsPurchasable")
    @Expose
    private Boolean isPurchasable;

    @SerializedName("IsRefundable")
    @Expose
    private Boolean isRefundable;

    @SerializedName("IsSaleable")
    @Expose
    private Boolean isSaleable;

    @SerializedName("IsSerialTracked")
    @Expose
    private Boolean isSerialTracked;

    @SerializedName("IsStoreCredit")
    @Expose
    private Boolean isStoreCredit;

    @SerializedName("IsTaxExempt")
    @Expose
    private Boolean isTaxExempt;

    @SerializedName("IsTaxOnly")
    @Expose
    private Boolean isTaxOnly;

    @SerializedName("IsTwoDimensionalMatrixItem")
    @Expose
    private Boolean isTwoDimensionalMatrixItem;

    @SerializedName("IsValid")
    @Expose
    private Boolean isValid;

    @SerializedName("IsWeighed")
    @Expose
    private Boolean isWeighed;

    @SerializedName("IsZeroValue")
    @Expose
    private Boolean isZeroValue;

    @SerializedName("Key")
    @Expose
    private String key;

    @SerializedName("LeadTime")
    @Expose
    private Integer leadTime;

    @SerializedName("LongDescription")
    @Expose
    private String longDescription;

    @SerializedName("LoyaltyPointsRedeemable")
    @Expose
    private Boolean loyaltyPointsRedeemable;

    @SerializedName("ManufacturerId")
    @Expose
    private String manufacturerId;

    @SerializedName("MaxDiscountAmount")
    @Expose
    private Double maxDiscountAmount;

    @SerializedName("MaxDiscountPercentage")
    @Expose
    private Double maxDiscountPercentage;

    @SerializedName("MaxQuantityPerTransaction")
    @Expose
    private Double maxQuantityPerTransaction;

    @SerializedName("MaximumOpenPrice")
    @Expose
    private Double maximumOpenPrice;

    @SerializedName("MerchandiseHierarchyDetailKey")
    @Expose
    private String merchandiseHierarchyDetailKey;

    @SerializedName("Message")
    @Expose
    private String message;

    @SerializedName("MinAge")
    @Expose
    private Integer minAge;

    @SerializedName("PackageGroupId")
    @Expose
    private String packageGroupId;

    @SerializedName("ParentProductId")
    @Expose
    private String parentProductId;

    @SerializedName("PreferedVendorId")
    @Expose
    private String preferedVendorId;

    @SerializedName("PriceOverrideAllowed")
    @Expose
    private Boolean priceOverrideAllowed;

    @SerializedName("ProductClassId")
    @Expose
    private String productClassId;

    @SerializedName("ProductDiscountGroupId")
    @Expose
    private String productDiscountGroupId;

    @SerializedName("ProductGroupId")
    @Expose
    private String productGroupId;

    @SerializedName("PurchaseTaxCodeId")
    @Expose
    private String purchaseTaxCodeId;

    @SerializedName("RequireAgeVerification")
    @Expose
    private Boolean requireAgeVerification;

    @SerializedName("ReturnDays")
    @Expose
    private Integer returnDays;

    @SerializedName("SaleDiscountsAllowed")
    @Expose
    private Boolean saleDiscountsAllowed;

    @SerializedName("SalesTaxCodeId")
    @Expose
    private String salesTaxCodeId;

    @SerializedName("ShortDescription")
    @Expose
    private String shortDescription;

    @SerializedName("SubsidiaryIds")
    @Expose
    private String subsidiaryIds;

    @SerializedName("UOMGroupId")
    @Expose
    private String uOMGroupId;

    @SerializedName("UPC")
    @Expose
    private String uPC;

    @SerializedName("VariantCode")
    @Expose
    private String variantCode;

    @SerializedName("UserFieldsList")
    @Expose
    private List<UserFieldsList> userFieldsList = null;

    @SerializedName("AssemblyComponents")
    @Expose
    private List<AssemblyComponent> assemblyComponents = null;

    @SerializedName("KitComponents")
    @Expose
    private List<KitComponent> kitComponents = null;

    @SerializedName("ProductInventoryList")
    @Expose
    private List<ProductInventoryList> productInventoryList = null;

    @SerializedName("ProductMerchandiseHierarchyDetailList")
    @Expose
    private List<ProductMerchandiseHierarchyDetailList> productMerchandiseHierarchyDetailList = null;

    @SerializedName("AttributeList")
    @Expose
    private List<AttributeList> attributeList = null;

    @SerializedName("InventoryLocationList")
    @Expose
    private List<InventoryLocationList> inventoryLocationList = null;

    @SerializedName("ApplicableSubsidiaries")
    @Expose
    private List<ApplicableSubsidiary> applicableSubsidiaries = null;

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

    public String getProductGroupId() {
        return this.productGroupId;
    }

    public void setProductGroupId(String str) {
        this.productGroupId = str;
    }

    public String getShortDescription() {
        return this.shortDescription;
    }

    public void setShortDescription(String str) {
        this.shortDescription = str;
    }

    public String getLongDescription() {
        return this.longDescription;
    }

    public void setLongDescription(String str) {
        this.longDescription = str;
    }

    public String getPreferedVendorId() {
        return this.preferedVendorId;
    }

    public void setPreferedVendorId(String str) {
        this.preferedVendorId = str;
    }

    public String getSalesTaxCodeId() {
        return this.salesTaxCodeId;
    }

    public void setSalesTaxCodeId(String str) {
        this.salesTaxCodeId = str;
    }

    public String getPurchaseTaxCodeId() {
        return this.purchaseTaxCodeId;
    }

    public void setPurchaseTaxCodeId(String str) {
        this.purchaseTaxCodeId = str;
    }

    public Boolean getAllowFractionalQuantity() {
        return this.allowFractionalQuantity;
    }

    public void setAllowFractionalQuantity(Boolean bool) {
        this.allowFractionalQuantity = bool;
    }

    public Boolean getDiscountsAllowed() {
        return this.discountsAllowed;
    }

    public void setDiscountsAllowed(Boolean bool) {
        this.discountsAllowed = bool;
    }

    public Boolean getIsBatchTracked() {
        return this.isBatchTracked;
    }

    public void setIsBatchTracked(Boolean bool) {
        this.isBatchTracked = bool;
    }

    public Boolean getIsExchangable() {
        return this.isExchangable;
    }

    public void setIsExchangable(Boolean bool) {
        this.isExchangable = bool;
    }

    public Boolean getIsNonStock() {
        return this.isNonStock;
    }

    public void setIsNonStock(Boolean bool) {
        this.isNonStock = bool;
    }

    public Boolean getIsRefundable() {
        return this.isRefundable;
    }

    public void setIsRefundable(Boolean bool) {
        this.isRefundable = bool;
    }

    public Boolean getIsSaleable() {
        return this.isSaleable;
    }

    public void setIsSaleable(Boolean bool) {
        this.isSaleable = bool;
    }

    public Boolean getIsSerialTracked() {
        return this.isSerialTracked;
    }

    public void setIsSerialTracked(Boolean bool) {
        this.isSerialTracked = bool;
    }

    public Boolean getIsWeighed() {
        return this.isWeighed;
    }

    public void setIsWeighed(Boolean bool) {
        this.isWeighed = bool;
    }

    public Boolean getIsKit() {
        return this.isKit;
    }

    public void setIsKit(Boolean bool) {
        this.isKit = bool;
    }

    public Boolean getIsAssembly() {
        return this.isAssembly;
    }

    public void setIsAssembly(Boolean bool) {
        this.isAssembly = bool;
    }

    public Boolean getCanLayaway() {
        return this.canLayaway;
    }

    public void setCanLayaway(Boolean bool) {
        this.canLayaway = bool;
    }

    public Boolean getCanOrder() {
        return this.canOrder;
    }

    public void setCanOrder(Boolean bool) {
        this.canOrder = bool;
    }

    public Boolean getIsValid() {
        return this.isValid;
    }

    public void setIsValid(Boolean bool) {
        this.isValid = bool;
    }

    public Boolean getIsOnHold() {
        return this.isOnHold;
    }

    public void setIsOnHold(Boolean bool) {
        this.isOnHold = bool;
    }

    public Boolean getIsTaxExempt() {
        return this.isTaxExempt;
    }

    public void setIsTaxExempt(Boolean bool) {
        this.isTaxExempt = bool;
    }

    public Boolean getIsOpenPrice() {
        return this.isOpenPrice;
    }

    public void setIsOpenPrice(Boolean bool) {
        this.isOpenPrice = bool;
    }

    public Boolean getIsOpenDescription() {
        return this.isOpenDescription;
    }

    public void setIsOpenDescription(Boolean bool) {
        this.isOpenDescription = bool;
    }

    public Boolean getIsInclusiveTaxed() {
        return this.isInclusiveTaxed;
    }

    public void setIsInclusiveTaxed(Boolean bool) {
        this.isInclusiveTaxed = bool;
    }

    public Double getDefaultQuantity() {
        return this.defaultQuantity;
    }

    public void setDefaultQuantity(Double d) {
        this.defaultQuantity = d;
    }

    public Double getBasePrice() {
        return this.basePrice;
    }

    public void setBasePrice(Double d) {
        this.basePrice = d;
    }

    public String getUPC() {
        return this.uPC;
    }

    public void setUPC(String str) {
        this.uPC = str;
    }

    public Boolean getRequireAgeVerification() {
        return this.requireAgeVerification;
    }

    public void setRequireAgeVerification(Boolean bool) {
        this.requireAgeVerification = bool;
    }

    public Integer getMinAge() {
        return this.minAge;
    }

    public void setMinAge(Integer num) {
        this.minAge = num;
    }

    public String getManufacturerId() {
        return this.manufacturerId;
    }

    public void setManufacturerId(String str) {
        this.manufacturerId = str;
    }

    public Integer getLeadTime() {
        return this.leadTime;
    }

    public void setLeadTime(Integer num) {
        this.leadTime = num;
    }

    public Boolean getIsZeroValue() {
        return this.isZeroValue;
    }

    public void setIsZeroValue(Boolean bool) {
        this.isZeroValue = bool;
    }

    public Boolean getIsPurchasable() {
        return this.isPurchasable;
    }

    public void setIsPurchasable(Boolean bool) {
        this.isPurchasable = bool;
    }

    public Boolean getPriceOverrideAllowed() {
        return this.priceOverrideAllowed;
    }

    public void setPriceOverrideAllowed(Boolean bool) {
        this.priceOverrideAllowed = bool;
    }

    public String getImageLocation() {
        return this.imageLocation;
    }

    public void setImageLocation(String str) {
        this.imageLocation = str;
    }

    public Boolean getCanSellExpiredItem() {
        return this.canSellExpiredItem;
    }

    public void setCanSellExpiredItem(Boolean bool) {
        this.canSellExpiredItem = bool;
    }

    public Boolean getCanRefundExpiredItem() {
        return this.canRefundExpiredItem;
    }

    public void setCanRefundExpiredItem(Boolean bool) {
        this.canRefundExpiredItem = bool;
    }

    public Boolean getLoyaltyPointsRedeemable() {
        return this.loyaltyPointsRedeemable;
    }

    public void setLoyaltyPointsRedeemable(Boolean bool) {
        this.loyaltyPointsRedeemable = bool;
    }

    public List<AssemblyComponent> getAssemblyComponents() {
        return this.assemblyComponents;
    }

    public void setAssemblyComponents(List<AssemblyComponent> list) {
        this.assemblyComponents = list;
    }

    public List<KitComponent> getKitComponents() {
        return this.kitComponents;
    }

    public void setKitComponents(List<KitComponent> list) {
        this.kitComponents = list;
    }

    public Double getMaximumOpenPrice() {
        return this.maximumOpenPrice;
    }

    public void setMaximumOpenPrice(Double d) {
        this.maximumOpenPrice = d;
    }

    public Boolean getIgnoreDiscountItemsForSaleDiscount() {
        return this.ignoreDiscountItemsForSaleDiscount;
    }

    public void setIgnoreDiscountItemsForSaleDiscount(Boolean bool) {
        this.ignoreDiscountItemsForSaleDiscount = bool;
    }

    public Boolean getSaleDiscountsAllowed() {
        return this.saleDiscountsAllowed;
    }

    public void setSaleDiscountsAllowed(Boolean bool) {
        this.saleDiscountsAllowed = bool;
    }

    public List<ProductInventoryList> getProductInventoryList() {
        return this.productInventoryList;
    }

    public void setProductInventoryList(List<ProductInventoryList> list) {
        this.productInventoryList = list;
    }

    public String getProductClassId() {
        return this.productClassId;
    }

    public void setProductClassId(String str) {
        this.productClassId = str;
    }

    public Boolean getHasPackageGroup() {
        return this.hasPackageGroup;
    }

    public void setHasPackageGroup(Boolean bool) {
        this.hasPackageGroup = bool;
    }

    public String getPackageGroupId() {
        return this.packageGroupId;
    }

    public void setPackageGroupId(String str) {
        this.packageGroupId = str;
    }

    public Boolean getIsGiftCertificate() {
        return this.isGiftCertificate;
    }

    public void setIsGiftCertificate(Boolean bool) {
        this.isGiftCertificate = bool;
    }

    public Integer getGiftCertificateType() {
        return this.giftCertificateType;
    }

    public void setGiftCertificateType(Integer num) {
        this.giftCertificateType = num;
    }

    public Integer getAutoSelectSerialBatchType() {
        return this.autoSelectSerialBatchType;
    }

    public void setAutoSelectSerialBatchType(Integer num) {
        this.autoSelectSerialBatchType = num;
    }

    public String getUOMGroupId() {
        return this.uOMGroupId;
    }

    public void setUOMGroupId(String str) {
        this.uOMGroupId = str;
    }

    public String getBarCodeMaskId() {
        return this.barCodeMaskId;
    }

    public void setBarCodeMaskId(String str) {
        this.barCodeMaskId = str;
    }

    public String getExternalLink() {
        return this.externalLink;
    }

    public void setExternalLink(String str) {
        this.externalLink = str;
    }

    public String getComment() {
        return this.comment;
    }

    public void setComment(String str) {
        this.comment = str;
    }

    public List<ProductMerchandiseHierarchyDetailList> getProductMerchandiseHierarchyDetailList() {
        return this.productMerchandiseHierarchyDetailList;
    }

    public void setProductMerchandiseHierarchyDetailList(List<ProductMerchandiseHierarchyDetailList> list) {
        this.productMerchandiseHierarchyDetailList = list;
    }

    public String getMerchandiseHierarchyDetailKey() {
        return this.merchandiseHierarchyDetailKey;
    }

    public void setMerchandiseHierarchyDetailKey(String str) {
        this.merchandiseHierarchyDetailKey = str;
    }

    public Boolean getHasAlternateProducts() {
        return this.hasAlternateProducts;
    }

    public void setHasAlternateProducts(Boolean bool) {
        this.hasAlternateProducts = bool;
    }

    public Boolean getHasUpsells() {
        return this.hasUpsells;
    }

    public void setHasUpsells(Boolean bool) {
        this.hasUpsells = bool;
    }

    public Boolean getIsMatrixItem() {
        return this.isMatrixItem;
    }

    public void setIsMatrixItem(Boolean bool) {
        this.isMatrixItem = bool;
    }

    public Boolean getIsEBTItem() {
        return this.isEBTItem;
    }

    public void setIsEBTItem(Boolean bool) {
        this.isEBTItem = bool;
    }

    public String getAlternateUPCCodes() {
        return this.alternateUPCCodes;
    }

    public void setAlternateUPCCodes(String str) {
        this.alternateUPCCodes = str;
    }

    public Integer getReturnDays() {
        return this.returnDays;
    }

    public void setReturnDays(Integer num) {
        this.returnDays = num;
    }

    public Boolean getIsTwoDimensionalMatrixItem() {
        return this.isTwoDimensionalMatrixItem;
    }

    public void setIsTwoDimensionalMatrixItem(Boolean bool) {
        this.isTwoDimensionalMatrixItem = bool;
    }

    public String getAttributes() {
        return this.attributes;
    }

    public void setAttributes(String str) {
        this.attributes = str;
    }

    public Boolean getAutoGenerateChildItemDefinition() {
        return this.autoGenerateChildItemDefinition;
    }

    public void setAutoGenerateChildItemDefinition(Boolean bool) {
        this.autoGenerateChildItemDefinition = bool;
    }

    public Integer getCostingMethod() {
        return this.costingMethod;
    }

    public void setCostingMethod(Integer num) {
        this.costingMethod = num;
    }

    public Integer getCostingSubMethod() {
        return this.costingSubMethod;
    }

    public void setCostingSubMethod(Integer num) {
        this.costingSubMethod = num;
    }

    public Boolean getIsMatrixChildItem() {
        return this.isMatrixChildItem;
    }

    public void setIsMatrixChildItem(Boolean bool) {
        this.isMatrixChildItem = bool;
    }

    public String getParentProductId() {
        return this.parentProductId;
    }

    public void setParentProductId(String str) {
        this.parentProductId = str;
    }

    public List<AttributeList> getAttributeList() {
        return this.attributeList;
    }

    public void setAttributeList(List<AttributeList> list) {
        this.attributeList = list;
    }

    public Boolean getIsTaxOnly() {
        return this.isTaxOnly;
    }

    public void setIsTaxOnly(Boolean bool) {
        this.isTaxOnly = bool;
    }

    public String getVariantCode() {
        return this.variantCode;
    }

    public void setVariantCode(String str) {
        this.variantCode = str;
    }

    public String getSubsidiaryIds() {
        return this.subsidiaryIds;
    }

    public void setSubsidiaryIds(String str) {
        this.subsidiaryIds = str;
    }

    public List<InventoryLocationList> getInventoryLocationList() {
        return this.inventoryLocationList;
    }

    public void setInventoryLocationList(List<InventoryLocationList> list) {
        this.inventoryLocationList = list;
    }

    public String getProductDiscountGroupId() {
        return this.productDiscountGroupId;
    }

    public void setProductDiscountGroupId(String str) {
        this.productDiscountGroupId = str;
    }

    public List<ApplicableSubsidiary> getApplicableSubsidiaries() {
        return this.applicableSubsidiaries;
    }

    public void setApplicableSubsidiaries(List<ApplicableSubsidiary> list) {
        this.applicableSubsidiaries = list;
    }

    public Double getCost() {
        return this.cost;
    }

    public void setCost(Double d) {
        this.cost = d;
    }

    public String getInventoryUOMId() {
        return this.inventoryUOMId;
    }

    public void setInventoryUOMId(String str) {
        this.inventoryUOMId = str;
    }

    public Boolean getIsStoreCredit() {
        return this.isStoreCredit;
    }

    public void setIsStoreCredit(Boolean bool) {
        this.isStoreCredit = bool;
    }

    public Double getMaxDiscountAmount() {
        return this.maxDiscountAmount;
    }

    public void setMaxDiscountAmount(Double d) {
        this.maxDiscountAmount = d;
    }

    public Double getMaxDiscountPercentage() {
        return this.maxDiscountPercentage;
    }

    public void setMaxDiscountPercentage(Double d) {
        this.maxDiscountPercentage = d;
    }

    public Double getMaxQuantityPerTransaction() {
        return this.maxQuantityPerTransaction;
    }

    public void setMaxQuantityPerTransaction(Double d) {
        this.maxQuantityPerTransaction = d;
    }

    public Boolean getAllowZeroPrice() {
        return this.allowZeroPrice;
    }

    public void setAllowZeroPrice(Boolean bool) {
        this.allowZeroPrice = bool;
    }

    public Boolean getIsDynamicAssembly() {
        return this.isDynamicAssembly;
    }

    public void setIsDynamicAssembly(Boolean bool) {
        this.isDynamicAssembly = bool;
    }

    public class ApplicableSubsidiary {

        @SerializedName("EnterpriseName")
        @Expose
        private String enterpriseName;

        @SerializedName("GenerateIntegrationEvent")
        @Expose
        private Boolean generateIntegrationEvent;

        @SerializedName("Key")
        @Expose
        private String key;

        @SerializedName("Message")
        @Expose
        private String message;

        @SerializedName("SourceId")
        @Expose
        private String sourceId;

        @SerializedName("SourceType")
        @Expose
        private Integer sourceType;

        @SerializedName("SubsidiaryId")
        @Expose
        private String subsidiaryId;

        @SerializedName("UserFieldsList")
        @Expose
        private List<UserFieldsList> userFieldsList = null;

        public ApplicableSubsidiary(ProductDetails productDetails) {
        }

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

        public String getSourceId() {
            return this.sourceId;
        }

        public void setSourceId(String str) {
            this.sourceId = str;
        }

        public String getSubsidiaryId() {
            return this.subsidiaryId;
        }

        public void setSubsidiaryId(String str) {
            this.subsidiaryId = str;
        }

        public Integer getSourceType() {
            return this.sourceType;
        }

        public void setSourceType(Integer num) {
            this.sourceType = num;
        }
    }

    public class AssemblyComponent {

        @SerializedName("EnterpriseName")
        @Expose
        private String enterpriseName;

        @SerializedName("GenerateIntegrationEvent")
        @Expose
        private Boolean generateIntegrationEvent;

        @SerializedName("Key")
        @Expose
        private String key;

        @SerializedName("Message")
        @Expose
        private String message;

        @SerializedName("ParentProductId")
        @Expose
        private String parentProductId;

        @SerializedName("ProductId")
        @Expose
        private String productId;

        @SerializedName("Quantity")
        @Expose
        private Double quantity;

        @SerializedName("UserFieldsList")
        @Expose
        private List<UserFieldsList> userFieldsList = null;

        public AssemblyComponent(ProductDetails productDetails) {
        }

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

        public String getParentProductId() {
            return this.parentProductId;
        }

        public void setParentProductId(String str) {
            this.parentProductId = str;
        }

        public String getProductId() {
            return this.productId;
        }

        public void setProductId(String str) {
            this.productId = str;
        }

        public Double getQuantity() {
            return this.quantity;
        }

        public void setQuantity(Double d) {
            this.quantity = d;
        }
    }

    public class AttributeList {

        @SerializedName("AttributeName")
        @Expose
        private String attributeName;

        @SerializedName("AttributeValue")
        @Expose
        private String attributeValue;

        @SerializedName("EnterpriseName")
        @Expose
        private String enterpriseName;

        @SerializedName("GenerateIntegrationEvent")
        @Expose
        private Boolean generateIntegrationEvent;

        @SerializedName("Key")
        @Expose
        private String key;

        @SerializedName("Message")
        @Expose
        private String message;

        @SerializedName("UserFieldsList")
        @Expose
        private List<UserFieldsList> userFieldsList = null;

        public AttributeList(ProductDetails productDetails) {
        }

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

        public String getAttributeName() {
            return this.attributeName;
        }

        public void setAttributeName(String str) {
            this.attributeName = str;
        }

        public String getAttributeValue() {
            return this.attributeValue;
        }

        public void setAttributeValue(String str) {
            this.attributeValue = str;
        }
    }

    public class InventoryLocationList {

        @SerializedName("AllocatedQuantity")
        @Expose
        private Double allocatedQuantity;

        @SerializedName("AvailableQuantity")
        @Expose
        private Double availableQuantity;

        @SerializedName("InReturnQuantity")
        @Expose
        private Double inReturnQuantity;

        @SerializedName("InStockQuantity")
        @Expose
        private Double inStockQuantity;

        @SerializedName("LocationId")
        @Expose
        private String locationId;

        @SerializedName("OnFulFillmentQuantity")
        @Expose
        private Double onFulFillmentQuantity;

        @SerializedName("OnLayawayQuantity")
        @Expose
        private Double onLayawayQuantity;

        @SerializedName("OnOrderQuantity")
        @Expose
        private Double onOrderQuantity;

        @SerializedName("ProductId")
        @Expose
        private String productId;

        @SerializedName("WarehouseId")
        @Expose
        private String warehouseId;

        public InventoryLocationList(ProductDetails productDetails) {
        }

        public String getProductId() {
            return this.productId;
        }

        public void setProductId(String str) {
            this.productId = str;
        }

        public String getWarehouseId() {
            return this.warehouseId;
        }

        public void setWarehouseId(String str) {
            this.warehouseId = str;
        }

        public String getLocationId() {
            return this.locationId;
        }

        public void setLocationId(String str) {
            this.locationId = str;
        }

        public Double getInStockQuantity() {
            return this.inStockQuantity;
        }

        public void setInStockQuantity(Double d) {
            this.inStockQuantity = d;
        }

        public Double getOnLayawayQuantity() {
            return this.onLayawayQuantity;
        }

        public void setOnLayawayQuantity(Double d) {
            this.onLayawayQuantity = d;
        }

        public Double getAvailableQuantity() {
            return this.availableQuantity;
        }

        public void setAvailableQuantity(Double d) {
            this.availableQuantity = d;
        }

        public Double getAllocatedQuantity() {
            return this.allocatedQuantity;
        }

        public void setAllocatedQuantity(Double d) {
            this.allocatedQuantity = d;
        }

        public Double getOnFulFillmentQuantity() {
            return this.onFulFillmentQuantity;
        }

        public void setOnFulFillmentQuantity(Double d) {
            this.onFulFillmentQuantity = d;
        }

        public Double getOnOrderQuantity() {
            return this.onOrderQuantity;
        }

        public void setOnOrderQuantity(Double d) {
            this.onOrderQuantity = d;
        }

        public Double getInReturnQuantity() {
            return this.inReturnQuantity;
        }

        public void setInReturnQuantity(Double d) {
            this.inReturnQuantity = d;
        }
    }

    public class KitComponent {

        @SerializedName("EnterpriseName")
        @Expose
        private String enterpriseName;

        @SerializedName("GenerateIntegrationEvent")
        @Expose
        private Boolean generateIntegrationEvent;

        @SerializedName("Key")
        @Expose
        private String key;

        @SerializedName("Message")
        @Expose
        private String message;

        @SerializedName("ParentProductId")
        @Expose
        private String parentProductId;

        @SerializedName("ProductId")
        @Expose
        private String productId;

        @SerializedName("Quantity")
        @Expose
        private Double quantity;

        @SerializedName("UserFieldsList")
        @Expose
        private List<UserFieldsList> userFieldsList = null;

        public KitComponent(ProductDetails productDetails) {
        }

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

        public String getParentProductId() {
            return this.parentProductId;
        }

        public void setParentProductId(String str) {
            this.parentProductId = str;
        }

        public String getProductId() {
            return this.productId;
        }

        public void setProductId(String str) {
            this.productId = str;
        }

        public Double getQuantity() {
            return this.quantity;
        }

        public void setQuantity(Double d) {
            this.quantity = d;
        }
    }

    public class ProductInventoryList {

        @SerializedName("AvailableQuantity")
        @Expose
        private Double availableQuantity;

        @SerializedName("AverageCost")
        @Expose
        private Double averageCost;

        @SerializedName("ConsiderInMRP")
        @Expose
        private Boolean considerInMRP;

        @SerializedName("CostProtectionMarginType")
        @Expose
        private Integer costProtectionMarginType;

        @SerializedName("CostProtectionMarginValue")
        @Expose
        private Double costProtectionMarginValue;

        @SerializedName("EnterpriseName")
        @Expose
        private String enterpriseName;

        @SerializedName("GenerateIntegrationEvent")
        @Expose
        private Boolean generateIntegrationEvent;

        @SerializedName("InStockQuantity")
        @Expose
        private Double inStockQuantity;

        @SerializedName("InTransitQuantity")
        @Expose
        private Double inTransitQuantity;

        @SerializedName("InventoryCycleId")
        @Expose
        private String inventoryCycleId;

        @SerializedName("IsInclusiveTaxed")
        @Expose
        private Boolean isInclusiveTaxed;

        @SerializedName("IsOnHold")
        @Expose
        private Boolean isOnHold;

        @SerializedName("IsTaxExempt")
        @Expose
        private Boolean isTaxExempt;

        @SerializedName("Key")
        @Expose
        private String key;

        @SerializedName("LeadTime")
        @Expose
        private Integer leadTime;

        @SerializedName("Locked")
        @Expose
        private Boolean locked;

        @SerializedName("MaximumOpenPrice")
        @Expose
        private Double maximumOpenPrice;

        @SerializedName("MaximumStockLevel")
        @Expose
        private Double maximumStockLevel;

        @SerializedName("Message")
        @Expose
        private String message;

        @SerializedName("MinimumOrderQuantity")
        @Expose
        private Double minimumOrderQuantity;

        @SerializedName("MinimumStockLevel")
        @Expose
        private Double minimumStockLevel;

        @SerializedName("NextCountDate")
        @Expose
        private String nextCountDate;

        @SerializedName("NextCountTime")
        @Expose
        private String nextCountTime;

        @SerializedName("OnFulFillmentQuantity")
        @Expose
        private Double onFulFillmentQuantity;

        @SerializedName("OnLayawayQuantity")
        @Expose
        private Double onLayawayQuantity;

        @SerializedName("OnOrderQuantity")
        @Expose
        private Double onOrderQuantity;

        @SerializedName("PreferedVendorId")
        @Expose
        private String preferedVendorId;

        @SerializedName("Price")
        @Expose
        private Double price;

        @SerializedName("ProductId")
        @Expose
        private String productId;

        @SerializedName("ProductTransactionType")
        @Expose
        private Integer productTransactionType;

        @SerializedName("PurchaseTaxCodeId")
        @Expose
        private String purchaseTaxCodeId;

        @SerializedName("SalesTaxCodeId")
        @Expose
        private String salesTaxCodeId;

        @SerializedName("UserFieldsList")
        @Expose
        private List<UserFieldsList> userFieldsList = null;

        @SerializedName("WarehouseId")
        @Expose
        private String warehouseId;

        public ProductInventoryList(ProductDetails productDetails) {
        }

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

        public String getProductId() {
            return this.productId;
        }

        public void setProductId(String str) {
            this.productId = str;
        }

        public String getWarehouseId() {
            return this.warehouseId;
        }

        public void setWarehouseId(String str) {
            this.warehouseId = str;
        }

        public String getPurchaseTaxCodeId() {
            return this.purchaseTaxCodeId;
        }

        public void setPurchaseTaxCodeId(String str) {
            this.purchaseTaxCodeId = str;
        }

        public String getSalesTaxCodeId() {
            return this.salesTaxCodeId;
        }

        public void setSalesTaxCodeId(String str) {
            this.salesTaxCodeId = str;
        }

        public Boolean getLocked() {
            return this.locked;
        }

        public void setLocked(Boolean bool) {
            this.locked = bool;
        }

        public String getInventoryCycleId() {
            return this.inventoryCycleId;
        }

        public void setInventoryCycleId(String str) {
            this.inventoryCycleId = str;
        }

        public Double getInStockQuantity() {
            return this.inStockQuantity;
        }

        public void setInStockQuantity(Double d) {
            this.inStockQuantity = d;
        }

        public Double getOnLayawayQuantity() {
            return this.onLayawayQuantity;
        }

        public void setOnLayawayQuantity(Double d) {
            this.onLayawayQuantity = d;
        }

        public Double getAvailableQuantity() {
            return this.availableQuantity;
        }

        public void setAvailableQuantity(Double d) {
            this.availableQuantity = d;
        }

        public Double getInTransitQuantity() {
            return this.inTransitQuantity;
        }

        public void setInTransitQuantity(Double d) {
            this.inTransitQuantity = d;
        }

        public Double getPrice() {
            return this.price;
        }

        public void setPrice(Double d) {
            this.price = d;
        }

        public Integer getCostProtectionMarginType() {
            return this.costProtectionMarginType;
        }

        public void setCostProtectionMarginType(Integer num) {
            this.costProtectionMarginType = num;
        }

        public Double getOnOrderQuantity() {
            return this.onOrderQuantity;
        }

        public void setOnOrderQuantity(Double d) {
            this.onOrderQuantity = d;
        }

        public Double getCostProtectionMarginValue() {
            return this.costProtectionMarginValue;
        }

        public void setCostProtectionMarginValue(Double d) {
            this.costProtectionMarginValue = d;
        }

        public Double getOnFulFillmentQuantity() {
            return this.onFulFillmentQuantity;
        }

        public void setOnFulFillmentQuantity(Double d) {
            this.onFulFillmentQuantity = d;
        }

        public Boolean getIsTaxExempt() {
            return this.isTaxExempt;
        }

        public void setIsTaxExempt(Boolean bool) {
            this.isTaxExempt = bool;
        }

        public Double getMinimumStockLevel() {
            return this.minimumStockLevel;
        }

        public void setMinimumStockLevel(Double d) {
            this.minimumStockLevel = d;
        }

        public Boolean getIsInclusiveTaxed() {
            return this.isInclusiveTaxed;
        }

        public void setIsInclusiveTaxed(Boolean bool) {
            this.isInclusiveTaxed = bool;
        }

        public Double getMaximumStockLevel() {
            return this.maximumStockLevel;
        }

        public void setMaximumStockLevel(Double d) {
            this.maximumStockLevel = d;
        }

        public Boolean getConsiderInMRP() {
            return this.considerInMRP;
        }

        public void setConsiderInMRP(Boolean bool) {
            this.considerInMRP = bool;
        }

        public Double getMaximumOpenPrice() {
            return this.maximumOpenPrice;
        }

        public void setMaximumOpenPrice(Double d) {
            this.maximumOpenPrice = d;
        }

        public Double getAverageCost() {
            return this.averageCost;
        }

        public void setAverageCost(Double d) {
            this.averageCost = d;
        }

        public Double getMinimumOrderQuantity() {
            return this.minimumOrderQuantity;
        }

        public void setMinimumOrderQuantity(Double d) {
            this.minimumOrderQuantity = d;
        }

        public Boolean getIsOnHold() {
            return this.isOnHold;
        }

        public void setIsOnHold(Boolean bool) {
            this.isOnHold = bool;
        }

        public String getPreferedVendorId() {
            return this.preferedVendorId;
        }

        public void setPreferedVendorId(String str) {
            this.preferedVendorId = str;
        }

        public Integer getProductTransactionType() {
            return this.productTransactionType;
        }

        public void setProductTransactionType(Integer num) {
            this.productTransactionType = num;
        }

        public Integer getLeadTime() {
            return this.leadTime;
        }

        public void setLeadTime(Integer num) {
            this.leadTime = num;
        }

        public String getNextCountDate() {
            return this.nextCountDate;
        }

        public void setNextCountDate(String str) {
            this.nextCountDate = str;
        }

        public String getNextCountTime() {
            return this.nextCountTime;
        }

        public void setNextCountTime(String str) {
            this.nextCountTime = str;
        }
    }

    public class ProductMerchandiseHierarchyDetailList {

        @SerializedName("EnterpriseName")
        @Expose
        private String enterpriseName;

        @SerializedName("GenerateIntegrationEvent")
        @Expose
        private Boolean generateIntegrationEvent;

        @SerializedName("HierarchyDetailId")
        @Expose
        private String hierarchyDetailId;

        @SerializedName("HierarchyDetailKey")
        @Expose
        private String hierarchyDetailKey;

        @SerializedName("HierarchyId")
        @Expose
        private String hierarchyId;

        @SerializedName("IsActive")
        @Expose
        private Boolean isActive;

        @SerializedName("Key")
        @Expose
        private String key;

        @SerializedName("Message")
        @Expose
        private String message;

        @SerializedName("ProductId")
        @Expose
        private String productId;

        @SerializedName("UserFieldsList")
        @Expose
        private List<UserFieldsList> userFieldsList = null;

        public ProductMerchandiseHierarchyDetailList(ProductDetails productDetails) {
        }

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

        public String getProductId() {
            return this.productId;
        }

        public void setProductId(String str) {
            this.productId = str;
        }

        public String getHierarchyId() {
            return this.hierarchyId;
        }

        public void setHierarchyId(String str) {
            this.hierarchyId = str;
        }

        public String getHierarchyDetailKey() {
            return this.hierarchyDetailKey;
        }

        public void setHierarchyDetailKey(String str) {
            this.hierarchyDetailKey = str;
        }

        public Boolean getIsActive() {
            return this.isActive;
        }

        public void setIsActive(Boolean bool) {
            this.isActive = bool;
        }

        public String getHierarchyDetailId() {
            return this.hierarchyDetailId;
        }

        public void setHierarchyDetailId(String str) {
            this.hierarchyDetailId = str;
        }
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

        public UserFieldsList(ProductDetails productDetails) {
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
