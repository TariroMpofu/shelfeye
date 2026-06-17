package com.citixsys.ivend_handheld.itemLookUp;

import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.recyclerview.widget.RecyclerView;
import com.citixsys.ivend_handheld.R;
import com.citixsys.ivend_handheld.listener.ViewHolderClickListener;
import java.lang.ref.WeakReference;

/* JADX INFO: loaded from: classes.dex */
public class ItemLookupViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {
    private TextView description;
    private TextView itemCode;
    private LinearLayout linearLayoutMain;
    private WeakReference<ViewHolderClickListener> mWeakReference;

    public ItemLookupViewHolder(View view) {
        super(view);
        this.itemCode = (TextView) view.findViewById(R.id.itemcode);
        this.description = (TextView) view.findViewById(R.id.description);
        this.linearLayoutMain = (LinearLayout) view.findViewById(R.id.ll_ILookupcontainer);
        view.setOnClickListener(this);
    }

    public void registerViewHolderListener(ViewHolderClickListener viewHolderClickListener) {
        this.mWeakReference = new WeakReference<>(viewHolderClickListener);
    }

    @Override // android.view.View.OnClickListener
    public void onClick(View view) {
        ViewHolderClickListener viewHolderClickListener = this.mWeakReference.get();
        if (viewHolderClickListener == null) {
            return;
        }
        viewHolderClickListener.onItemClick(getLinearLayoutMain(), getAbsoluteAdapterPosition());
    }

    public TextView getItemCode() {
        return this.itemCode;
    }

    public void setItemCode(TextView textView) {
        this.itemCode = textView;
    }

    public TextView getDescription() {
        return this.description;
    }

    public void setDescription(TextView textView) {
        this.description = textView;
    }

    public LinearLayout getLinearLayoutMain() {
        return this.linearLayoutMain;
    }

    public void setLinearLayoutMain(LinearLayout linearLayout) {
        this.linearLayoutMain = linearLayout;
    }
}
