package com.company.assembleegameclient.util.redrawers {
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.util.PointUtil;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.GradientType;
import flash.display.Shape;
import flash.filters.BitmapFilterQuality;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.Dictionary;

public class GlowRedrawer {

    private static const GRADIENT_MAX_SUB:uint = 0x282828;
    private static const GLOW_FILTER:GlowFilter = new GlowFilter(0, 0.3, 12, 12, 1.5, BitmapFilterQuality.LOW, false, false);
    private static const GLOW_FILTER_ALT:GlowFilter = new GlowFilter(0, 0.5, 16, 16, 2, BitmapFilterQuality.LOW, false, false);

    private static var tempMatrix_:Matrix = new Matrix();
    private static var gradient_:Shape = getGradient();
    private static var glowHashes:Dictionary = new Dictionary();

    public static function outlineGlow(oBmd:BitmapData, color:uint, scale:Number = 1.4, caching:Boolean = true) {
        var hash:String = getHash(color, scale);
        if (caching && isCached(oBmd, hash))
            return (glowHashes[oBmd][hash]);

        var bmd:BitmapData = oBmd.clone();
        tempMatrix_.identity();
        tempMatrix_.scale(oBmd.width / 0x0100, oBmd.height / 0x0100);
        bmd.draw(gradient_, tempMatrix_, null, BlendMode.SUBTRACT);
        var _local7:Bitmap = new Bitmap(oBmd);
        bmd.draw(_local7, null, null, BlendMode.ALPHA);
        TextureRedrawer.OUTLINE_FILTER.blurX = scale;
        TextureRedrawer.OUTLINE_FILTER.blurY = scale;
        TextureRedrawer.OUTLINE_FILTER.color = 0;
        bmd.applyFilter(bmd, bmd.rect, PointUtil.ORIGIN, TextureRedrawer.OUTLINE_FILTER);
        if (color != 0xFFFFFFFF) {
            if (Parameters.isGpuRender() && color != 0) {
                GLOW_FILTER_ALT.color = color;
                bmd.applyFilter(bmd, bmd.rect, PointUtil.ORIGIN, GLOW_FILTER_ALT);
            }
            else {
                GLOW_FILTER.color = color;
                bmd.applyFilter(bmd, bmd.rect, PointUtil.ORIGIN, GLOW_FILTER);
            }
        }
        if (caching)
            cache(oBmd, color, scale, bmd);
        return (bmd);
    }

    private static function cache(tex:BitmapData, glowColor:uint, outlineSize:Number, newTex:BitmapData):void {
        var glowHash:Object = null;
        var hash:String = getHash(glowColor, outlineSize);
        if ((tex in glowHashes)) {
            glowHashes[tex][hash] = newTex;
        }
        else {
            glowHash = {};
            glowHash[hash] = newTex;
            glowHashes[tex] = glowHash;
        }
    }

    private static function isCached(_arg1:BitmapData, _arg2:String):Boolean {
        var _local3:Object;
        if ((_arg1 in glowHashes)) {
            _local3 = glowHashes[_arg1];
            if ((_arg2 in _local3)) {
                return (true);
            }
        }
        return (false);
    }

    public static function clearCache():void {
        for (var tex:Object in glowHashes) {
            var hashMap:Object = glowHashes[tex];
            for (var hash:String in hashMap) {
                delete hashMap[hash];
            }
            delete glowHashes[tex];
        }
    }

    private static function getHash(_arg1:uint, _arg2:Number):String {
        return ((int((_arg2 * 10)).toString() + _arg1));
    }

    private static function getGradient():Shape {
        var _local1:Shape = new Shape();
        var _local2:Matrix = new Matrix();
        _local2.createGradientBox(0x0100, 0x0100, (Math.PI / 2), 0, 0);
        _local1.graphics.beginGradientFill(GradientType.LINEAR, [0, GRADIENT_MAX_SUB], [1, 1], [127, 0xFF], _local2);
        _local1.graphics.drawRect(0, 0, 0x0100, 0x0100);
        _local1.graphics.endFill();
        return (_local1);
    }
}
}