import QtQuick 1.1
import com.nokia.symbian 1.1
import "../../js/main.js" as Script
import "../Component"
import "../Silica"

MyPage {
    id: page;

    property string threadId;
    property variant thread: null;

    property int currentPage: 0;
    property int totalPage: 0;
    property bool hasMore: false;
    property bool hasPrev: false;
    property int bottomPage: 0;
    property int topPage: 0;

    property bool isReverse: false;
    property bool isLz: false;

    property int privateFullPage: 0;
    onIsLzChanged: {
        if (isLz) privateFullPage = totalPage;
        else totalPage = privateFullPage;
    }

    function positionAtTop(){
        internal.openContextMenu();
    }
    function focus(){
        view.forceActiveFocus();
    }

    function getlist(option){
        option = option||"renew";
        var opt = {
            kz: threadId,
            model: view.model
        }
        if (isReverse) opt.r = 1;
        if (isLz) opt.lz = 1;
        if (option === "renew"){
            opt.renew = true;
            if (isReverse)
                opt.pn = totalPage;
        } else if (option === "next"){
            if (isReverse && bottomPage == 1){
                signalCenter.showMessage(qsTr("First page now"));
                return;
            }
            if (hasMore)
                opt.pn = isReverse ? bottomPage - 1
                                   : bottomPage + 1;
            else {
                opt.pn = bottomPage;
                opt.dirty = true;
            }
        } else if (option === "prev"){
            if (!isReverse && topPage == 1){
                getlist("renew");
                return;
            }
            opt.insert = true;
            if (hasPrev)
                opt.pn = isReverse ? topPage + 1
                                   : topPage - 1;
            else {
                opt.pn = topPage;
                opt.dirty = true;
            }
        } else if (option === "jump"){
            opt.renew = true;
            opt.pn = currentPage;
        }
        function s(obj, modelAffected){
            loading = false;
            thread = obj.thread;
            currentPage = obj.page.current_page;
            totalPage = obj.page.total_page;

            if (option === "renew"||option === "jump"){
                hasMore = obj.page.has_more === "1";
                hasPrev = obj.page.has_prev === "1";
                bottomPage = currentPage;
                topPage = currentPage;
            } else if (option === "next"){
                hasMore = obj.page.has_more === "1";
                bottomPage = currentPage;
            } else if (option === "prev"){
                hasPrev = obj.page.has_prev === "1";
                topPage = currentPage;
            }
            if (!modelAffected)
                signalCenter.showMessage(qsTr("No more posts"));
        }
        function f(err){
            loading = false;
            signalCenter.showMessage(err);
        }
        loading = true;
        Script.getThreadPage(opt, s, f);
    }

    title: thread ? thread.title : qsTr("New tab");

    SilicaListView {
        id: view;
        anchors.fill: parent;
        cacheBuffer: view.height*5;
        model: ListModel {}
        delegate: ThreadDelegate {
        }
        footer: FooterItem {
            visible: view.count > 0;
            enabled: !loading;
            onClicked: getlist("next");
        }
        header: PullToActivate {
            myView: view;
            enabled: !loading;
            onRefresh: getlist("prev");
        }
    }

    ScrollDecorator {
        flickableItem: view;
        platformInverted: tbsettings.whiteTheme;
    }
}