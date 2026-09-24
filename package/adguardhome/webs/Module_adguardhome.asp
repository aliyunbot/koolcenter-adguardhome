<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<title>AdGuard Home</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="res/softcenter.css">
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<style>
#agh-app .agh-warn{margin:10px 0;padding:9px 11px;border:1px solid rgba(224,160,0,.75);background:rgba(224,160,0,.08);line-height:1.6}
#agh-app .agh-small{font-size:11px;opacity:.72;line-height:1.6}
#agh-app .agh-state{font-weight:bold}
#agh-app .agh-row{display:flex;flex-wrap:wrap;align-items:center;gap:7px;margin:4px 0}
#agh-app .agh-row label{font-weight:bold}
#agh-app .agh-note{font-size:12px;opacity:.78;line-height:1.6}
#agh-app .agh-value{font-weight:bold;word-break:break-all}
#agh-app .agh-ok{color:#45b97c;font-weight:bold}
#agh-app .agh-error{color:#ff6b6b;font-weight:bold}
#agh-app .agh-field{box-sizing:border-box;max-width:100%}
#agh-app .agh-url-input{width:430px}
#agh-app .agh-rules{box-sizing:border-box;width:100%;min-height:110px;resize:vertical}
#agh-app .agh-table-wrap{width:100%;overflow-x:auto}
#agh-app .agh-filter-table{min-width:690px;table-layout:auto}
#agh-app .agh-filter-table td.url{max-width:330px;word-break:break-all}
#agh-app .agh-filter-table button{cursor:pointer}
#agh-app #agh-result,#agh-app #agh-check-result{box-sizing:border-box;min-height:22px;padding:7px;white-space:pre-wrap;word-break:break-word;border:1px solid rgba(127,127,127,.45);background:rgba(127,127,127,.08)}
#agh-app .agh-section{margin-top:10px}
#agh-app .agh-return{float:right;width:15px;height:25px;margin-top:10px}
#agh-app .agh-return img{cursor:pointer;position:absolute;margin-left:-30px;margin-top:-25px}
@media(max-width:720px){
  #agh-app .agh-row{align-items:stretch;flex-direction:column}
  #agh-app .agh-row .button_gen{width:100%}
  #agh-app .agh-url-input,#agh-app .agh-field{width:100%}
}
</style>
</head>
<body onload="init();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<table class="content" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <td width="17">&nbsp;</td>
    <td valign="top" width="202">
      <div id="mainMenu"></div>
      <div id="subMenu"></div>
    </td>
    <td valign="top">
      <div id="tabMenu" class="submenuBlock"></div>
      <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
        <tr>
          <td align="left" valign="top">
            <table width="760" border="0" cellpadding="5" cellspacing="0" class="FormTitle" id="FormTitle">
              <tr>
                <td colspan="3" valign="top">
                  <div>&nbsp;</div>
                  <div class="formfonttitle" style="float:left;">AdGuard Home</div>
                  <div class="agh-return"><img id="return_btn" onclick="reload_Soft_Center();" title="返回软件中心" src="/images/backprev.png" onmouseover="this.src='/images/backprevclick.png'" onmouseout="this.src='/images/backprev.png'" alt="返回软件中心"></div>
                  <div class="splitLine" style="clear:both;margin:30px 0 10px 5px;"></div>
                  <div id="agh-app">
                    <div style="margin-left:5px;line-height:1.6;">AdGuard Home 过滤订阅管理</div>
                    <div class="agh-warn">本插件只让 AdGuard Home 监听 127.0.0.1:6053，SmartDNS upstream 为 127.0.0.1:7913；不会接管 53，也不会修改 dnsmasq。过滤订阅由 AdGuard Home 原生 API 管理。</div>
                    <div class="agh-small">core_integration=pending; port53_touched=0; dnsmasq_hook=not_installed</div>
<!-- UPSTREAM_STATUS_BEGIN -->
<!-- UPSTREAM_STATUS_END -->

                    <div class="agh-section">
                      <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
                        <thead><tr><td colspan="4">运行状态</td></tr></thead>
                        <tr><th>服务状态</th><td colspan="3"><span id="agh-state" class="agh-state">读取中...</span></td></tr>
                        <tr><th>Filtering</th><td><span id="agh-enabled" class="agh-value">-</span></td><th>已加载过滤器</th><td><span id="agh-count" class="agh-value">-</span></td></tr>
                        <tr><th>规则总数</th><td><span id="agh-rules" class="agh-value">-</span></td><th>自动更新间隔</th><td><span id="agh-interval-status" class="agh-value">-</span></td></tr>
                      </table>
                    </div>

                    <div class="agh-section">
                      <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
                        <thead><tr><td colspan="2">过滤开关与更新</td></tr></thead>
                        <tr><th>启用过滤</th><td><label><input type="checkbox" id="agh-filter-enabled"> 启用 AdGuard Home 过滤</label></td></tr>
                        <tr><th>自动更新</th><td><select id="agh-interval" class="input_option"><option value="6">6 小时</option><option value="12">12 小时</option><option value="24">24 小时</option><option value="48">48 小时</option><option value="168">7 天</option></select></td></tr>
                        <tr><th>操作</th><td><div class="agh-row"><button type="button" class="button_gen" id="agh-save-config">保存设置</button><button type="button" class="button_gen" id="agh-refresh">立即更新全部订阅</button></div><div class="agh-note">更新由 AGH 在路由器本机执行。失败会保留上一次可用规则，不执行远程内容。</div></td></tr>
                      </table>
                    </div>

                    <div class="agh-section">
                      <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
                        <thead><tr><td colspan="2">订阅规则列表</td></tr></thead>
                        <tr><th>预设订阅</th><td><div class="agh-row"><select id="agh-preset" class="input_option agh-field"></select><button type="button" class="button_gen" id="agh-add-preset">订阅预设</button></div></td></tr>
                        <tr><th>自定义订阅</th><td><div class="agh-row"><input id="agh-name" class="input_ss_table agh-field" placeholder="自定义名称" size="20"><input id="agh-url" class="input_ss_table agh-field agh-url-input" placeholder="https://.../filter.txt" size="52"><button type="button" class="button_gen" id="agh-add-custom">添加订阅</button></div></td></tr>
                        <tr><td colspan="2"><div class="agh-table-wrap"><table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable agh-filter-table"><thead><tr><th>启用</th><th>名称</th><th>URL</th><th>规则数</th><th>最后更新</th><th>操作</th></tr></thead><tbody id="agh-filter-rows"><tr><td colspan="6">读取中...</td></tr></tbody></table></div></td></tr>
                      </table>
                    </div>

                    <div class="agh-section">
                      <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
                        <thead><tr><td colspan="2">过滤效果验证</td></tr></thead>
                        <tr><th>测试域名</th><td><div class="agh-row"><input id="agh-check-host" class="input_ss_table agh-field" placeholder="例如 ads.example.com" size="40"><button type="button" class="button_gen" id="agh-check">检查是否命中过滤规则</button></div></td></tr>
                        <tr><th>检查结果</th><td><div id="agh-check-result">check_host 会调用 AGH 原生过滤引擎并返回匹配原因、规则文本和 filter id；这不是仅检查 URL 是否可下载。</div><div class="agh-note" style="margin-top:7px;">实际客户端链路仍需把 DNS 请求送到本机 6053；当前 dnsmasq 53 未接管，所以可用路由器本机 dig/kdig 或指定客户端 DNS 做端到端验证。</div></td></tr>
                      </table>
                    </div>

                    <div class="agh-section">
                      <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
                        <thead><tr><td colspan="2">自定义规则</td></tr></thead>
                        <tr><th>规则内容</th><td><textarea id="agh-user-rules" class="input_ss_table agh-rules" placeholder="每行一条 AdGuard/uBlock 规则"></textarea></td></tr>
                        <tr><th>操作</th><td><div class="agh-row"><button type="button" class="button_gen" id="agh-save-rules">保存自定义规则</button><span class="agh-note">保存会调用 AGH /control/filtering/set_rules，不会执行规则内容。</span></div></td></tr>
                      </table>
                    </div>

                    <div class="agh-section"><div id="agh-result">就绪</div></div>
                    <div class="KoolshareBottom" style="margin-top:35px;">AdGuard Home filtering adapter for KoolCenter</div>
                  </div>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
    <td width="10" align="center" valign="top"></td>
  </tr>
</table>
<div id="footer"></div>
<script>
function menu_hook(){
  tabtitle[tabtitle.length-1]=new Array("","AdGuard Home");
  tablink[tablink.length-1]=new Array("","Module_adguardhome.asp");
}
function reload_Soft_Center(){location.href="/Module_Softcenter.asp";}
function init(){
  show_menu(menu_hook);
  initAdGuardHome();
}
function initAdGuardHome(){
  var preset=[
    {name:"AdGuard DNS filter",url:"https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt",note:"AdGuard curated aggregate"},
    {name:"AdGuard Chinese filter",url:"https://filters.adtidy.org/extension/ublock/filters/224.txt",note:"EasyList China + AdGuard Chinese filter"},
    {name:"HaGeZi Multi NORMAL",url:"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/multi.txt",note:"Balanced all-round list"},
    {name:"217heidai 规则1",url:"https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockdns.txt",note:"AdGuard Home 合并 DNS 规则"},
    {name:"anti-AD",url:"https://anti-ad.net/easylist.txt",note:"anti-AD official AdGuard Home list"}
  ];
  var result=document.getElementById("agh-result");
  function setResult(text,ok){result.textContent=text;result.className=ok?"agh-ok":"agh-error";}
  function esc(text){return String(text==null?"":text).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/\"/g,"&quot;");}
  function loadUpstreamStatus(){
    request("upstream",[],function(data){
      var box=document.getElementById("agh-upstream-status");if(!box)return;
      var badge=data.verify_display==="verified"?"verified":"not_verified";
      var lines=["upstream_mode="+data.mode,"upstream_host="+data.host,"upstream_port="+data.port,"upstream_effective="+data.effective_host+":"+data.effective_port,"upstream_verify_state="+data.verify_state,"upstream_verify_source="+data.verify_source,"upstream_manual_verified="+data.manual_verified,"upstream_verify_display="+data.verify_display,"upstream_pass_state="+data.pass_state,"upstream_probe_state="+data.probe_state,"upstream_probe_source="+data.probe_source,"upstream_probe_owner="+data.probe_owner,"upstream_probe_reason="+data.probe_reason,"core_integration="+data.core_integration,"dbus_transport="+data.dbus_transport,"port53_touched="+data.port53_touched,"dnsmasq_hook="+data.dnsmasq_hook,"router_mutation="+data.router_mutation];
      box.innerHTML="<p>验证展示：<strong class=\""+badge+"\">"+esc(data.verify_display)+"</strong>。unknown/candidate/pending/failed 不是 verified。</p><pre id=\"upstream-current\">"+esc(lines.join("\n"))+"</pre>";
    });
  }
  function request(action,args,cb){
    var id=Math.floor(Math.random()*90000000)+10000000;
    var xhr=new XMLHttpRequest();
    xhr.open("POST","/_api/",true);xhr.setRequestHeader("Content-Type","application/json");
    xhr.onreadystatechange=function(){
      if(xhr.readyState!==4)return;
      if(xhr.status!==200){setResult("API 请求失败 HTTP "+xhr.status,false);return;}
      var ack;try{ack=JSON.parse(xhr.responseText||"{}");}catch(e){setResult("API 返回不是 JSON",false);return;}
      if(String(ack.result)!==String(id)){setResult("API 未确认请求: "+(ack.error||"unknown"),false);return;}
      var out=new XMLHttpRequest();out.open("GET","/_temp/adguardhome_filters.json?_="+new Date().getTime(),true);
      out.onreadystatechange=function(){if(out.readyState!==4)return;if(out.status!==200){setResult("读取操作结果失败",false);return;}var data;try{data=JSON.parse(out.responseText||"{}");}catch(e){setResult("操作结果不是 JSON",false);return;}if(data.ok===false){setResult(data.error||"操作失败",false);return;}cb(data);};out.send();
    };
    xhr.send(JSON.stringify({id:id,method:"adguardhome_filters.sh",params:[action].concat(args||[]),fields:{}}));
  }
  function renderStatus(data){
    var filters=data.filters||[], total=0;
    filters.forEach(function(f){total+=Number(f.rules_count||0);});
    document.getElementById("agh-enabled").textContent=data.enabled?"已启用":"已关闭";
    document.getElementById("agh-count").textContent=filters.length;
    document.getElementById("agh-rules").textContent=total;
    document.getElementById("agh-interval-status").textContent=(data.interval||0)+" 小时";
    document.getElementById("agh-filter-enabled").checked=!!data.enabled;
    document.getElementById("agh-interval").value=String(data.interval||24);
    var body=document.getElementById("agh-filter-rows");body.innerHTML="";
    if(!filters.length){body.innerHTML="<tr><td colspan=\"6\">当前没有加载任何广告过滤订阅。</td></tr>";}
    filters.forEach(function(f){
      var tr=document.createElement("tr"), c0=document.createElement("td"), c1=document.createElement("td"), c2=document.createElement("td"), c3=document.createElement("td"), c4=document.createElement("td"), c5=document.createElement("td");
      var check=document.createElement("input");check.type="checkbox";check.checked=!!f.enabled;check.onchange=function(){request("set",[f.url,f.url,f.name,check.checked?"1":"0"],function(d){renderStatus(d);setResult("订阅状态已更新",true);});};c0.appendChild(check);
      c1.textContent=f.name||"(未命名)";c2.className="url";c2.textContent=f.url;c3.textContent=String(f.rules_count||0);c4.textContent=f.last_updated||"未更新";
      var remove=document.createElement("button");remove.type="button";remove.className="button_gen";remove.textContent="删除";remove.onclick=function(){if(window.confirm("删除订阅并移除其规则？")){request("remove",[f.url],function(d){renderStatus(d);setResult("订阅已删除",true);});}};c5.appendChild(remove);tr.appendChild(c0);tr.appendChild(c1);tr.appendChild(c2);tr.appendChild(c3);tr.appendChild(c4);tr.appendChild(c5);body.appendChild(tr);
    });
    document.getElementById("agh-state").textContent="运行中 / 过滤 API 已连接";
    if(data.user_rules){document.getElementById("agh-user-rules").value=data.user_rules.join("\n");}
  }
  function load(){request("status",[],function(d){renderStatus(d);setResult("状态已读取",true);});}
  preset.forEach(function(p,i){var o=document.createElement("option");o.value=String(i);o.textContent=p.name+" - "+p.note;document.getElementById("agh-preset").appendChild(o);});
  document.getElementById("agh-add-preset").onclick=function(){var p=preset[Number(document.getElementById("agh-preset").value)||0];request("add",[p.url,p.name],function(d){renderStatus(d);setResult("已订阅 "+p.name,true);});};
  document.getElementById("agh-add-custom").onclick=function(){var n=document.getElementById("agh-name").value.trim(),u=document.getElementById("agh-url").value.trim();request("add",[u,n],function(d){renderStatus(d);setResult("自定义订阅已添加",true);});};
  document.getElementById("agh-refresh").onclick=function(){request("refresh",[],function(d){renderStatus(d);setResult("全部订阅已刷新",true);});};
  document.getElementById("agh-save-config").onclick=function(){var en=document.getElementById("agh-filter-enabled").checked?"1":"0",iv=document.getElementById("agh-interval").value;request("config",[en,iv],function(d){renderStatus(d);setResult("过滤设置已保存",true);});};
  document.getElementById("agh-check").onclick=function(){var h=document.getElementById("agh-check-host").value.trim();request("check",[h],function(d){var rules=d.rules||[];document.getElementById("agh-check-result").textContent=rules.length?"命中: "+(d.reason||"blocked")+"\n"+rules.map(function(r){return "filter="+r.filter_list_id+" rule="+r.text;}).join("\n"):"未命中过滤规则。reason="+(d.reason||"NotFiltered");setResult("check_host 已完成",true);});};
  document.getElementById("agh-save-rules").onclick=function(){request("rules",[document.getElementById("agh-user-rules").value],function(d){renderStatus(d);setResult("自定义规则已保存",true);});};
  load();
  loadUpstreamStatus();
}
</script>
</body>
</html>
