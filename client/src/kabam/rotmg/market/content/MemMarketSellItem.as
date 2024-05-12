package kabam.rotmg.market.content {
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.ui.TextButton;
import com.company.assembleegameclient.ui.dialogs.Dialog;
import com.company.assembleegameclient.util.FilterUtil;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextFieldAutoSize;

import io.decagames.rotmg.ui.buttons.SliceScalingButton;
import io.decagames.rotmg.ui.defaults.DefaultLabelFormat;
import io.decagames.rotmg.ui.texture.TextureParser;

import kabam.rotmg.market.utils.DialogUtils;
import kabam.rotmg.market.utils.GeneralUtils;
import kabam.rotmg.messaging.impl.data.MarketData;

public class MemMarketSellItem extends MemMarketItem
{
    private var removeButton_:TextButton;
    private var priceText_:SimpleText;
    private var timeText_:SimpleText;
    private var currency_:Bitmap;

    public function MemMarketSellItem(gameSprite:GameSprite, data:MarketData)
    {
        super(gameSprite, OFFER_WIDTH, OFFER_HEIGHT, 80, data.itemType_, data);
        this.icon_.x = -3;
        this.icon_.y = -3;

        this.removeButton_ = new TextButton(16, "Remove", 80);
        this.removeButton_.x = 58;
        this.removeButton_.y = 24;
        this.removeButton_.addEventListener(MouseEvent.CLICK, this.onRemoveClick);
        addChild(this.removeButton_);

        var size:int = this.data_.price_ > 9999 ? 13 : 14;
        this.priceText_ = new SimpleText(size, 0xFFFFFF, false);
        this.priceText_.setBold(true);
        this.priceText_.text = this.data_.price_.toString();
        this.priceText_.x = 135 - this.priceText_.width / 2;
        this.priceText_.y = 2;
        this.priceText_.filters = FilterUtil.getTextOutlineFilter();
        addChild(this.priceText_);

        var unix:Number = this.data_.timeLeft_ * 1000;
        var later:Date = new Date(unix);
        var now:Date = new Date();
        var ms:Number = Math.floor(later.time - now.time);
        var hours:Number = ms / 3600000;
        this.timeText_ = new SimpleText(10, 0xFFFFFF, false, width, 0);
        this.timeText_.setBold(true);
        this.timeText_.htmlText = "<p align=\"center\">" + hours.toFixed(1) + "h</p>";
        this.timeText_.wordWrap = true;
        this.timeText_.multiline = true;
        this.timeText_.autoSize = TextFieldAutoSize.CENTER;
        this.timeText_.x = -75;
        this.timeText_.y = 32;
        this.timeText_.filters = FilterUtil.getTextOutlineFilter();
        addChild(this.timeText_);

        this.currency_ = new Bitmap(GeneralUtils.getFameIcon(24));
        this.currency_.x = 50;
        this.currency_.y = -4;
        addChild(this.currency_);
    }

    private function onRemoveClick(event:MouseEvent) : void
    {
        var dialog:Dialog = new DialogUtils().returnDialog(this.gameSprite_, "Verification", "Are you sure you want to remove this item?", "Yes", "No");

        dialog.addEventListener(Dialog.BUTTON1_EVENT, this.onVerified);
        dialog.addEventListener(Dialog.BUTTON2_EVENT, DialogUtils.onDialogClose);

        this.gameSprite_.mui_.layers.overlay.addChild(dialog);
    }

    private function onVerified(event:Event) : void
    {
        this.gameSprite_.gsc_.marketRemove(this.id_);
        this.removeDialog(event.target as Dialog);
    }

    private function removeDialog(dialog:Dialog) : void
    {
        dialog.removeEventListener(Dialog.BUTTON1_EVENT, this.onVerified);
        dialog.removeEventListener(Dialog.BUTTON1_EVENT, DialogUtils.onDialogClose);
        dialog.removeEventListener(Dialog.BUTTON2_EVENT, DialogUtils.onDialogClose);
        dialog.parent.removeChild(dialog);
    }

    /* Clear */
    public override function dispose() : void
    {
        this.removeButton_.removeEventListener(MouseEvent.CLICK, this.onRemoveClick);
        this.removeButton_ = null;
        this.priceText_ = null;
        this.timeText_ = null;
        this.currency_ = null;

        super.dispose();
    }
}
}
